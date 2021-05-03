#include "mycache.h"
#include "cache_ref.h"
#include<cstring>
CacheRefModel::CacheRefModel(MyCache *_top, size_t memory_size)
    : top(_top), scope(top->VCacheTop), mem(memory_size) {
    /**
     * TODO (Lab3) setup reference model :)
     */
    
    mem.set_name("ref");
}

void CacheRefModel::reset() {
    /**
     * TODO (Lab3) reset reference model :)
     */
    state=IDLE;
    memset(buffer,0,sizeof(buffer));
    memset(ca,0,sizeof(ca));
    memset(cp,0,sizeof(cp));
    csn=0;hit_num_r=0;
    hit=0;
    log_debug("ref: reset()\n");
    mem.reset();
}

auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t {
    /**
     * TODO (Lab3) implement load operation for reference model :)
     */
    
    log_debug("ref: load(0x%x, %d)\n", addr, 1 << size);
    addr_t start = (addr>>4)<<4;
    csn=(start>>4)&0x3;
    hit=0;
    for(int i=0;i<4;i++){
        if(ca[csn][i].valid&&ca[csn][i].index==(start>>6)<<6){
            hit=1;hit_num=i;break;
        }
    }
    if(!hit){
        while(1){
            if(!ca[csn][cp[csn]].now){
                hit_num=cp[csn];break;
            }
            ca[csn][cp[csn]].now=0;
            cp[csn]=(cp[csn]+1)%4;
        }
        for(int i=0;i<4;i++){
            int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
            int data=buffer[csn][hit_num][i];
            if(ca[csn][hit_num].dirty) mem.store(tmp,data,0b1111);
            buffer[csn][hit_num][i]=mem.load(start+4*i);
        }
        ca[csn][hit_num].dirty=0;
        ca[csn][hit_num].now=1;
        ca[csn][hit_num].index=(start>>6)<<6;
    }
    else{
        ca[csn][hit_num].now=1;
    }
    return buffer[csn][hit_num][(addr>>2)&0x3];
}

void CacheRefModel::store(addr_t addr, AXISize size, word_t strobe, word_t data) {
    /**
     * TODO (Lab3) implement store operation for reference model :)
     */

    log_debug("ref: store(0x%x, %d, %x, \"%08x\")\n", addr, 1 << size, strobe, data);
    addr_t start = (addr>>4)<<4;
    csn=(start>>4)&0x3;
    hit=0;
    for(int i=0;i<4;i++){
        if(ca[csn][i].valid&&ca[csn][i].index==(start>>6)<<6){
            hit=1;hit_num=i;break;
        }
    }
    if(!hit){
        while(1){
            if(!ca[csn][cp[csn]].now){
                hit_num=cp[csn];break;
            }
            ca[csn][cp[csn]].now=0;
            cp[csn]=(cp[csn]+1)%4;
        }
        for(int i=0;i<4;i++){
            int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
            int data=buffer[csn][hit_num][i];
            if(ca[csn][hit_num].dirty) mem.store(tmp,data,0b1111);
            buffer[csn][hit_num][i]=mem.load(start+4*i);
        }
        ca[csn][hit_num].dirty=0;
        ca[csn][hit_num].now=1;
        ca[csn][hit_num].index=(start>>6)<<6;
    }
    else{
        ca[csn][hit_num].now=1;
    }
    buffer[csn][hit_num][(addr>>2)&0x3]=buffer[csn][hit_num][(addr>>2)&0x3]&(~strobe)|strobe&data;
    ca[csn][hit_num].dirty=1;
}

void CacheRefModel::check_internal() {
    /**
     * TODO (Lab3) compare reference model's internal states to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     */

    log_debug("ref: check_internal()\n");

    /**
     * the following comes from StupidBuffer's reference model.
     */
    for (int i = 0; i < 4; i++) {
        for(int j=0;j<4;j++){
            for(int k=0;k<4;k++){
                asserts(
                    buffer[i][j][k] == scope->mem[i][j][k],
                    "reference model's internal state is different from RTL model."
                    " at mem[%x], expected = %08x, got = %08x",
                    i, buffer[i][j][k], scope->mem[i][j][k]
                );
            }
        }
    }
}

void CacheRefModel::check_memory() {
    /**
     * TODO (Lab3) compare reference model's memory to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     *       you can use mem.dump() and MyCache::dump() to get the full contents
     *       of both memories.
     */

    log_debug("ref: check_memory()\n");

    /**
     * the following comes from StupidBuffer's reference model.
     */
    asserts(mem.dump(0, mem.size()) == top->dump(), "reference model's memory content is different from RTL model");
}
