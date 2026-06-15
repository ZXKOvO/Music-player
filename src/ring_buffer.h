#pragma once
#include <vector>
#include <mutex>
#include <condition_variable>
#include <atomic>

// 线程安全环形缓冲区，用于解码线程（生产者）与播放线程（消费者）之间传递 PCM 数据
class RingBuffer {
public:
    // 构造指定容量的环形缓冲区
    explicit RingBuffer(size_t capacity);

    // 生产者：写入 PCM 数据，阻塞直到有足够空间，返回实际写入字节数
    size_t write(const uint8_t *data, size_t size);

    // 消费者：非阻塞读取，有多少读多少
    size_t read(uint8_t *data, size_t size);

    size_t readable() const;   // 当前可读字节数
    size_t writable() const;   // 当前可写字节数
    void clear();              // 重置缓冲区，清空数据并清除 EOF 标志
    void setEof(bool eof);    // 标记 EOF
    bool isEof() const;       // 查询是否已标记 EOF

private:
    std::vector<uint8_t> buf_;
    size_t capacity_;
    size_t head_ = 0;   // 读位置
    size_t tail_ = 0;   // 写位置
    size_t count_ = 0;  // 已用字节数
    mutable std::mutex mutex_;
    std::condition_variable notFull_;   // 缓冲区非满时唤醒生产者
    std::condition_variable notEmpty_;  // 缓冲区非空时唤醒消费者
    std::atomic<bool> eof_{false};      // 解码结束标志
};
