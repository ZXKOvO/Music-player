#include "ring_buffer.h"
#include <cstring>
#include <algorithm>

// 构造指定容量的环形缓冲区
RingBuffer::RingBuffer(size_t capacity)
    : buf_(capacity), capacity_(capacity) {}

// 生产者写入：阻塞等待可用空间，将数据分两段拷贝（处理环形回绕），返回实际写入字节数
size_t RingBuffer::write(const uint8_t *data, size_t size) {
    std::unique_lock lock(mutex_);
    size_t written = 0;
    while (written < size) {
        // 等待缓冲区有空间，或收到 EOF 信号
        notFull_.wait(lock, [&] { return count_ < capacity_ || eof_; });
        if (eof_) return written;

        size_t avail = capacity_ - count_;
        size_t chunk = std::min(avail, size - written);

        // 分两段拷贝：尾部 → 头部（处理环形回绕）
        size_t first = std::min(chunk, capacity_ - tail_);
        std::memcpy(buf_.data() + tail_, data + written, first);
        if (first < chunk) {
            std::memcpy(buf_.data(), data + written + first, chunk - first);
        }

        tail_ = (tail_ + chunk) % capacity_;
        count_ += chunk;
        written += chunk;
        notEmpty_.notify_one();
    }
    return written;
}

// 消费者读取：有数据时立即返回部分结果，无数据时阻塞等待，返回实际读取字节数
size_t RingBuffer::read(uint8_t *data, size_t size) {
    std::unique_lock lock(mutex_);
    size_t bytesRead = 0;
    while (bytesRead < size) {
        if (count_ == 0) {
            if (eof_) break;                    // EOF 且无数据，直接返回
            if (bytesRead > 0) break;           // 已读到部分数据，不再阻塞等待
            notEmpty_.wait(lock, [&] { return count_ > 0 || eof_; });
            if (count_ == 0 && eof_) break;
        }

        size_t chunk = std::min(count_, size - bytesRead);

        // 分两段拷贝：尾部 → 头部（处理环形回绕）
        size_t first = std::min(chunk, capacity_ - head_);
        std::memcpy(data + bytesRead, buf_.data() + head_, first);
        if (first < chunk) {
            std::memcpy(data + bytesRead + first, buf_.data(), chunk - first);
        }

        head_ = (head_ + chunk) % capacity_;
        count_ -= chunk;
        bytesRead += chunk;
        notFull_.notify_one();
    }
    return bytesRead;
}

// 返回当前缓冲区中可读的字节数
size_t RingBuffer::readable() const {
    std::lock_guard lock(mutex_);
    return count_;
}

// 返回当前缓冲区中可写的字节数
size_t RingBuffer::writable() const {
    std::lock_guard lock(mutex_);
    return capacity_ - count_;
}

// 重置缓冲区：清空数据并清除 EOF 标志，唤醒所有等待的生产者
void RingBuffer::clear() {
    std::lock_guard lock(mutex_);
    head_ = tail_ = count_ = 0;
    eof_ = false;
    notFull_.notify_all();
}

// 设置 EOF 标志并唤醒所有等待数据的消费者，使其能正常退出
void RingBuffer::setEof(bool eof) {
    std::lock_guard lock(mutex_);
    eof_ = eof;
    notEmpty_.notify_all(); // 唤醒可能在等待数据的消费者
}

// 查询是否已标记 EOF（解码结束）
bool RingBuffer::isEof() const {
    return eof_.load();
}
