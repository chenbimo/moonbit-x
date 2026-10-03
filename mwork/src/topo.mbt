///|
/// Order selected members so that a member never publishes before a selected
/// member it imports. Stable: ties keep the moon.work member order.
pub fn topo_sort(
  selected : Array[Member],
  items : Array[Member],
) -> Array[Member] {
  // Member name → member, for import resolution.
  let by_name : Map[String, Member] = Map([])
  for item in items {
    by_name[item.name] = item
  }
  let selected_names : Map[String, Unit] = Map([])
  for item in selected {
    selected_names[item.name] = ()
  }
  // Kahn's algorithm over the selected subgraph.
  let deps : Map[String, Int] = Map([])
  let dependents : Map[String, Array[String]] = Map([])
  for item in selected {
    deps[item.name] = 0
    dependents[item.name] = []
  }
  for item in selected {
    for imported in item.imports {
      match by_name.get(imported) {
        Some(target) =>
          if selected_names.contains(target.name) {
            // item imports target: target publishes first.
            let current = match deps.get(item.name) {
              Some(count) => count
              None => 0
            }
            deps[item.name] = current + 1
            dependents[target.name].push(item.name)
          }
        None => ()
      }
    }
  }
  let order : Array[Member] = []
  let ready : Array[String] = []
  for item in selected {
    let count = match deps.get(item.name) {
      Some(count) => count
      None => 0
    }
    if count == 0 {
      ready.push(item.name)
    }
  }
  while ready.length() > 0 {
    let name = ready.remove(0)
    for item in selected {
      if item.name == name {
        order.push(item)
        break
      }
    }
    match dependents.get(name) {
      Some(list) =>
        for dependent in list {
          let rest = match deps.get(dependent) {
            Some(count) => count - 1
            None => 0
          }
          deps[dependent] = rest
          if rest == 0 {
            ready.push(dependent)
          }
        }
      None => ()
    }
  }
  // Cycles cannot happen between real modules; append leftovers defensively.
  for item in selected {
    let mut found = false
    for done in order {
      if done.name == item.name {
        found = true
        break
      }
    }
    if !found {
      order.push(item)
    }
  }
  order
}
