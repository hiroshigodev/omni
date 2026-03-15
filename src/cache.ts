export class LRUCache<K, V> {
  private capacity: number;
  private ttl: number; // in milliseconds
  private cache: Map<K, { value: V; expiry: number }>;

  constructor(capacity: number, ttl: number = 3600000) { // Default 1 hour
    this.capacity = capacity;
    this.ttl = ttl;
    this.cache = new Map();
  }

  get(key: K): V | undefined {
    const entry = this.cache.get(key);
    if (entry !== undefined) {
      if (Date.now() > entry.expiry) {
        this.cache.delete(key);
        return undefined;
      }
      // Refresh existence and update TTL
      this.cache.delete(key);
      this.cache.set(key, { value: entry.value, expiry: Date.now() + this.ttl });
      return entry.value;
    }
    return undefined;
  }

  set(key: K, value: V): void {
    if (this.cache.has(key)) {
      this.cache.delete(key);
    } else if (this.cache.size >= this.capacity) {
      // Remove oldest (first in Map)
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey !== undefined) {
        this.cache.delete(oldestKey);
      }
    }
    this.cache.set(key, { value, expiry: Date.now() + this.ttl });
  }

  clearExpired(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiry) {
        this.cache.delete(key);
      }
    }
  }
}
