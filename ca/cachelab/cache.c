//------------------------------------------------------------------------------
// 4190.308                     Computer Architecture                  Fall 2015
//
// Cache Simulator Lab
//
// File: cache.c
//
// (C) 2015 Computer Systems and Platforms Laboratory, Seoul National University
//
// Changelog
// 20151119   bernhard    created
//

#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include "cache.h"

char RP_STR[RP_MAX+1][32] = {
  "round robin", "random", "LRU (least-recently used)",
  "MRU (most-recently used)", "LFU (least-frequently used)",
  "MFU (most-frequently used)"
};

char WP_STR[2][20] = {
  "write-allocate", "no write-allocate"
};

int lg(uint32 n)
{//don't want to include math library,
 //n is known to be power of 2 - cnt is int
  int cnt=0;
  while(n > 1) {
    n /= 2;
    cnt++;
  }
  return cnt;

}

void check_param(uint32 capacity, uint32 blocksize, uint32 ways)
{//test cache parameters
  //   - capacity, blocksize, and ways must be powers of 2
  assert( ISPOW2(capacity) && ISPOW2(blocksize) && ISPOW2(ways) );
  //   - capacity must be >= blocksize
  assert( capacity >= blocksize );
  //   - number of blocks >= the number of ways
  assert( (capacity / blocksize) >= ways );
}


Cache* create_cache(uint32 capacity, uint32 blocksize, uint32 ways,
                    uint32 rp, uint32 wp, uint32 verbosity)
{
  int i;
  uint32 sets;
  uint32 tagshift;
  Cache *c;

  /*check cache parameters*/
  check_param(capacity, blocksize, ways);

  //get number of sets
  sets = capacity / (blocksize * ways);
  tagshift = lg(blocksize * sets);


  c = calloc(1, sizeof(Cache));
  //set parameters
  c->capacity = capacity;
  c->blocksize = blocksize;
  c->ways = ways;
  c->sets = sets;
  c->tagshift = tagshift;
  c->rp = rp;
  c->wp = wp;
  

  //allocate sets
  c->set = malloc(sizeof(Set) * sets);

  //for each set, allocate lines
  for (i = 0; i < sets; i++) {
    c->set[i].way = calloc(ways, sizeof(Line));
    c->set[i].rr = 0; //round robin base = 0
  }
  // 3. print cache configuration
  printf("cache configuration:\n"
         "  capacity:        %6u\n"
         "  blocksize:       %6u\n"
         "  ways:            %6u\n"
         "  sets:            %6u\n"
         "  tag shift:       %6u\n"
         "  replacement:     %s\n"
         "  on write miss:   %s\n"
         "\n",
         capacity, blocksize, ways, sets, tagshift, RP_STR[rp], WP_STR[wp]); 

  // 4. return c
  return c;
}

void delete_cache(Cache *c)
{//free the cache
  int i;
  for (i = 0; i < c->sets; i++) {
    free(c->set[i].way);
  }
  free(c->set);
  free(c);
}

int line_access(Cache *c, Line *l, uint32 tag)
{//access the cache and return hit/miss
  int i;
  int hit = 0;

  for (i = 0; i < c->ways; i++) {
    //increment unaccessed, valid line's age
    l[i].age += l[i].valid; //use valid bit to increment age
    if (l[i].valid == 1 && l[i].tag == tag) {
      l[i].age = 0;
      hit = 1;
    }
  }
  return hit;
}


int line_alloc(Cache *c, Line *l, uint32 tag)
{//search for empty lines to put tag
  int i;
  for (i = 0; i < c->ways; i++) {
    if (l[i].valid == 0) {//empty line
      l[i].tag = tag;
      l[i].valid = 1;
      l[i].age = 0;
      return 1; //success
    }
  }
  return 0; //fail : cache is full
}

uint32 set_find_victim(Cache *c, Set *s)
{//choose victim according to c's replacement policy
  int victim=0;
  int max=0; 
  int i;
  switch (c->rp) {
    case RP_RR:
      victim = ((s->rr ++) % c->ways);
      break;
    case RP_RANDOM: 
      victim = rand() % c->ways;
      break;
    case RP_LRU: 
      max = s->way[0].age;
      for (i = 1; i < c->ways; i++) {//search oldest line
        //every line would be valid, but check validity just in case
        if (s->way[i].valid == 1 && max < s->way[i].age) {
          max = s->way[i].age;
          victim = i;
        }
      }
      break;
    default: //not implemented
      return EXIT_FAILURE;
  }

  return victim;
}

void replace_victim(Cache *c, Set *s, uint32 tag, uint32 victim)
{//change victim line's tag with new one
  s->way[victim].tag = tag;
  s->way[victim].age = 0;
}

//the only visible interface
void cache_access(Cache *c, uint32 type, uint32 address, uint32 length)
{
  uint32 victim=0;
  //compute block offset (although not needed in this implementation)
  uint32 bl_offset = c->blocksize - 1; //fill bitmask with 1s
  bl_offset = address & bl_offset;

  //compute set index
  address >>= lg(c->blocksize); 
  uint32 set_i = c->sets - 1;//fill bitmask with 1s
  set_i = address & set_i;

  //compute tag
  uint32 tag = (address >> lg(c->sets));

  if ( line_access(c, c->set[set_i].way, tag) )
    c->s_hit++;
  else 
  {//missed
    c->s_miss++;
    if ( !(type == WRITE && c->wp == WP_NOWRITEALLOC) ) 
    {//if type=W && NO_WR_ALLOC, do nothing to the cache when there is a miss
      if ( !( line_alloc(c, c->set[set_i].way, tag) ) )
      {//failed to allocate new data: choose a victim
        victim = set_find_victim(c, &c->set[set_i]);
        replace_victim(c, &c->set[set_i], tag, victim);
        c->s_evict++;
      }
    }
  }

  c->s_access++;
  return;
}
