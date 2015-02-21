Todo program
--
Simple TODO program in cmdline.
```bash
$todo -h
Usage: todo [options]

    -a, --all                        Show all tasks (complete tasks)
    -u, --update task_num,level      Update task using id
    -n, --new task,level             Adding a task to todo
    -d, --del task                   Delete a task
```

It will create and update ```~/.todo.yaml``` file:
```yaml
---
faire les courses: 1
faire le menage: 42
manger: 10
trouver du taf: 70
```
