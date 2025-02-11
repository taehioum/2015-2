package ds.hash;
//(h(K) + p(k,i)) mod M
public class HashTable 
{
  Integer[] ht;
  private int M;
  Probe probe;
  
		
  public HashTable(int n) {
    M = n;
    ht = new Integer[M];
  }

  public void start(String policy, int c1, int c2, int c3){
    probe = new Probe(policy, c1, c2, c3);
  }

  public void insert(int value) {
    int key=0;
    for (int i=0;i<M;i++) {
      key = (h(value) + probe.p(i)) % M;
      //System.out.printf("%d: %d\n", i, key);
      if (ht[key] == null) {
        ht[key] = value;
        break;
      }
    }
  }

  public int find(int value) {
    int key=0;
    //maximum number of collisions can be number of inputs
    for (int i=0;i<M;i++) {
      key = (h(value) + probe.p(i)) % M;
      if (ht[key] == null)
        break;
      //place this afterwards to avoid null-pointer-exception
      else if (ht[key] == value)
        return key;
    }
    return -1;
  }

  private int h(int K)
  {
    return K % M;
  }

  private class Probe
  {
    int c1, c2, c3;
    String policy;
    public Probe(String policy, int c1, int c2, int c3)
    {
      this.c1 = c1;
      this.c2 = c2;
      this.c3 = c3;
      this.policy = policy;
    }

    public int p(int i)
    {
      int val = 0;
      if (i == 0) return 0; 
      switch (policy) {
        case "linear" :
          val =  c1 * i;
          break;
        case "quadratic" :
          val = (c1 * i * i) + (c2 * i) + c3 ; 
          break;
      }     
      return val;
    }
  }
}
