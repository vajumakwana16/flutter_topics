import 'package:flutter/material.dart';
import 'package:flutter_topics/models/task_model.dart';
import 'package:provider/provider.dart';

class ExRiverPod extends StatelessWidget {
  ExRiverPod({super.key});

  TextEditingController name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    print("refresh");
    final taskProvider = context.read<TaskProvider>();
final completed = taskProvider.tasks.where((t)=>t.isDone == true).toList().length;
    return Scaffold(
        appBar: AppBar(title: Text("Provider Example")),
        floatingActionButton: FloatingActionButton(onPressed: () {}),
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 10,
              child: LinearProgressIndicator(
                  value: (completed/taskProvider.tasks.length)),
            ),
            TextField(controller: name),
            TextButton(
              child: Text("Add"),
              onPressed: () => taskProvider.addTask(Task(name.text, "", false)),
            ),
            TextButton(
              child: Text("Clear"),
              onPressed: () => taskProvider.clearTask(),
            ),
        Expanded(
          child:Consumer<TaskProvider>(
              builder: (BuildContext context, value, Widget? child) {
                return  ListView.builder(
                    shrinkWrap: true,
                      itemCount: taskProvider.tasks.length,
                      itemBuilder: (context, i) {
                        final task = taskProvider.tasks[i];
                        return ListTile(
                          trailing: Checkbox(value: task.isDone, onChanged: (v)=>taskProvider.toggle(task)),
                            title:Text(task.title));
                      }
                );
              },
            )),
          ],
        )

    );
  }
}

class TaskProvider extends ChangeNotifier {
  List<Task> tasks = [];

  TaskProvider();

  void addTask(Task task) {
    tasks.add(task);
    notifyListeners();
  }

  void clearTask() {
    tasks.clear();
    notifyListeners();
  }

  void toggle(Task t) {
    final task = tasks.where((tsk)=>tsk == t).first;
    task.isDone = !task.isDone;
    notifyListeners();
  }
}