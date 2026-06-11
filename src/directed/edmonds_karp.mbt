// Edmonds-Karp maximum flow algorithm.
//
// Reference: Edmonds, J., & Karp, R. M. (1972). "Theoretical improvements in
// algorithmic efficiency for network flow problems". JACM, 19(2), 248-264.

///|
/// Sentinel for "no bottleneck found yet" — the maximum `Int` value.
const EK_INT_MAX : Int = 2147483647

///|
/// Compute the maximum s-t flow in a flow network with integer capacities,
/// using BFS to find shortest augmenting paths. Runs in O(V * E^2).
///
/// ## Parameters
/// - `nodes`: all graph nodes
/// - `capacity`: map from `(u, v)` directed edges to edge capacity
/// - `source`: source node
/// - `sink`: sink node
///
/// ## Returns
/// The maximum flow value (integer).
pub fn[N : Eq + Hash] edmonds_karp(
  nodes : Array[N],
  capacity : Map[(N, N), Int],
  source : N,
  sink : N,
) -> Int {
  // Sparse residual graph: only real edges and their reverse edges are
  // materialized (capacity 0 for the reverse direction), keeping memory
  // at O(E) instead of O(V^2).
  let residual : Map[(N, N), Int] = Map([])
  let adj : Map[N, Array[N]] = Map([])
  fn add_neighbor(a : N, b : N) -> Unit {
    let lst = adj.get(a).unwrap_or([])
    let mut present = false
    for x in lst {
      if x == b {
        present = true
        break
      }
    }
    if !present {
      lst.push(b)
      adj[a] = lst
    }
  }

  for k_v in capacity {
    let (edge, cap) = k_v
    let (u, v) = edge
    residual[edge] = residual.get(edge).unwrap_or(0) + cap
    if !residual.contains((v, u)) {
      residual[(v, u)] = 0
    }
    add_neighbor(u, v)
    add_neighbor(v, u)
  }
  ignore(nodes)
  let mut total_flow = 0
  while true {
    // BFS to find an augmenting path from source to sink.
    let parent : Map[N, N] = Map([])
    let visited : Map[N, Bool] = Map([])
    visited[source] = true
    let queue : Array[N] = [source]
    let mut head = 0
    let mut found = false
    while head < queue.length() && !found {
      let u = queue[head]
      head += 1
      for v in adj.get(u).unwrap_or([]) {
        if visited.contains(v) {
          continue
        }
        let c = residual.get((u, v)).unwrap_or(0)
        if c > 0 {
          visited[v] = true
          parent[v] = u
          if v == sink {
            found = true
            break
          }
          queue.push(v)
        }
      }
    }
    if !found {
      break
    }
    // Find bottleneck.
    let mut bottleneck = EK_INT_MAX
    let mut v = sink
    while v != source {
      let u = parent.get(v).unwrap()
      let c = residual.get((u, v)).unwrap()
      if c < bottleneck {
        bottleneck = c
      }
      v = u
    }
    // Update residual capacities along the path.
    let mut v2 = sink
    while v2 != source {
      let u = parent.get(v2).unwrap()
      residual[(u, v2)] = residual.get((u, v2)).unwrap() - bottleneck
      residual[(v2, u)] = residual.get((v2, u)).unwrap() + bottleneck
      v2 = u
    }
    total_flow += bottleneck
  }
  total_flow
}
