#pragma once

#include "defs.h"
#include "memory.h"
#include "reference.h"

class MyCache;

class CacheRefModel final : public ICacheRefModel {
public:
    CacheRefModel(MyCache *_top, size_t memory_size);

    void reset();
    auto load(addr_t addr, AXISize size) -> word_t;
    void store(addr_t addr, AXISize size, word_t strobe, word_t data);
    void check_internal();
    void check_memory();

private:
    MyCache *top;
    VModelScope *scope;

    /**
     * TODO (Lab3) declare reference model's memory and internal states :)
     *
     * NOTE: you can use BlockMemory, or replace it with anything you like.
     */
    enum {IDLE,FETCH,READY,FLUSH} state;
    word_t buffer[4][4][4];
    struct cache_line{
        bool valid,dirty,now;
        int index;
    }ca[4][4];
    int cp[4];
    int csn,hit_num;
    bool hit;
    BlockMemory mem;
};
