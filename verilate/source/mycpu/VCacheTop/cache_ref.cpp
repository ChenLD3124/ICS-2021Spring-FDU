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
    csn=0;hit_num=0;
    hit=0;
    log_debug("ref: reset()\n");
    mem.reset();
}

auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t {
    /**
     * TODO (Lab3) implement load operation for reference model :)
     */
    
    
    addr_t start = (addr>>4)<<4;
    csn=(start>>4)&0x3;
    hit=0;
    for(int i=0;i<4;i++){
        if(ca[csn][i].valid&&ca[csn][i].index==((start>>6)<<6)){
            hit=1;hit_num=i;
            break;
        }
    }
    if(!hit){
        for(int i=0;i<5;i++){
            if(ca[csn][(i+cp[csn])%4].now){
                ca[csn][(i+cp[csn])%4].now=0;
            }
            else{
                hit_num=(i+cp[csn])%4;
                cp[csn]=(hit_num+1)%4;
                break;
            }                  
        }
        if(ca[csn][hit_num].dirty){
            for(int i=0;i<4;i++){
                int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
                int data=buffer[csn][hit_num][i];
                mem.store(tmp,data,0xffffffff);
            }
            
        }
        for(int i=0;i<4;i++){
            int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
            buffer[csn][hit_num][i]=mem.load(start+4*i);
        }
        ca[csn][hit_num].dirty=0;
        
        
        ca[csn][hit_num].index=(start>>6)<<6;
    }
    log_debug("ref: load(0x%x, %d) get 0x%x\n", addr, 1 << size,buffer[csn][hit_num][(addr>>2)&0x3]);
    ca[csn][hit_num].now=1;ca[csn][hit_num].valid=1;
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
        if(ca[csn][i].valid&&ca[csn][i].index==((start>>6)<<6)){
            hit=1;hit_num=i;
            break;
        }
    }
    if(!hit){
        for(int i=0;i<5;i++){
            if(ca[csn][(i+cp[csn])%4].now){
                ca[csn][(i+cp[csn])%4].now=0;
            }
            else{
                hit_num=(i+cp[csn])%4;
                cp[csn]=(hit_num+1)%4;
                break;
            }                  
        }
        
        if(ca[csn][hit_num].dirty){
            for(int i=0;i<4;i++){
                int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
                int data=buffer[csn][hit_num][i];
                mem.store(tmp,data,0xffffffff);
            }
            
        }
        for(int i=0;i<4;i++){
            int tmp=(ca[csn][hit_num].index)+(csn<<4)+(i<<2);
            buffer[csn][hit_num][i]=mem.load(start+4*i);
        }
        ca[csn][hit_num].dirty=0;
        ca[csn][hit_num].valid=1;
        ca[csn][hit_num].index=(start>>6)<<6;
    }
    
    int mask;
    mask=0xff000000*((strobe&0x8)!=0)|0x00ff0000*((strobe&0x4)!=0)|0x0000ff00*((strobe&0x2)!=0)|0x000000ff*((strobe&0x1)!=0);
    buffer[csn][hit_num][(addr>>2)&0x3]=(buffer[csn][hit_num][(addr>>2)&0x3]&(~mask))|(mask&data);
    ca[csn][hit_num].dirty=1;
    ca[csn][hit_num].valid=1;
    ca[csn][hit_num].now=1;
    // ca[csn][hit_num].index=(start>>6)<<6;
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
    /*for(int i=0;i<4;i++){
        for(int j=0;j<4;j++){
            asserts(
                ca[i][j].now == scope->can[16*i+4*j+2],
                // "reference model's internal state is different from RTL model."
                " ca expected = %08x, got = %08x in %08x %08x index 0x%x 0x%x",
                ca[i][j].now, scope->can[16*i+4*j+2],i,j,ca[i][j].index,scope->can[16*i+4*j+3]
            );
        }
    }*/
    for (int i = 0; i < 4; i++) {
        for(int j=0;j<4;j++){
            for(int k=0;k<4;k++){
                if(ca[i][j].valid){
                    asserts(
                        buffer[i][j][k] == scope->mem[i*16+j*4+k],
                        // "reference model's internal state is different from RTL model."
                        " at mem[%x], expected = %08x, got = %08x",
                        i*16+j*4+k, buffer[i][j][k], scope->mem[i*16+j*4+k]
                    );
                    asserts(
                        cp[i] == scope->cpn[i],
                        // "reference model's internal state is different from RTL model."
                        " cp expected = %08x, got = %08x",
                        cp[i], scope->cpn[i]
                    );
                    
                }
                
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
