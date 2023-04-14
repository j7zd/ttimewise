// V 0.1.0
// This code is subject to change

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

var database;
//database helper funtions
Future<void> deleteDatabase(String path) =>
    databaseFactory.deleteDatabase(path);
Future<void> insertTask(TaskData task) async {
  final Database db = await database;
  await db.insert(
    'tasks',
    task.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, Object?>>> getTaskByDate(int date) async {
  final Database db = await database;
  final List<Map<String, Object?>> maps =
      await db.query('tasks', where: 'date = ?', whereArgs: [date]);
  return maps;
}

// delete a task by object
Future<void> deleteTask(TaskData task) async {
  final Database db = await database;
  await db.delete('tasks',
      where: 'date = ? AND name = ? AND start = ? AND end = ?',
      whereArgs: [task.date, task.name, task.startTime, task.endTime]);
}

int toInt(TimeOfDay myTime) => myTime.hour * 60 + myTime.minute;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = openDatabase(join(await getDatabasesPath(), 'timewise.db'),
      version: 1, onCreate: (db, version) {
    return db.execute(
        'CREATE TABLE tasks(date TEXT, name TEXT, start INTEGER, end INTEGER, description TEXT, colour INTEGER)');
  });
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Day(),
          
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
            child: Builder(
              builder: (BuildContext innerContext) {
                return IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(innerContext).openDrawer();
                  },
                );
              },
            ),
          ),
          
        ],
      ),
      drawer: Drawer( // going to add more options soon
          backgroundColor: const Color.fromARGB(255, 20, 20, 20),
          child: Column(
            children: [
              const IntrinsicWidth(
                stepWidth: double.infinity,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color(0xFF256D7B),
                  ),
                  child: Text(
                    'TimeWise',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ListTile(
                title: const Text(
                  'Version: 0.1.0',
                  style: TextStyle(color: Color(0xFF6C4675)),
                ),
                onTap: () {},
              ),
            ],
          )),
    );
  }
}

// class day is a pageview that contains each day.

class Day extends StatefulWidget {
  const Day({super.key});

  @override
  State<Day> createState() => _DayState();
}

class _DayState extends State<Day> {
  final PageController controller = PageController(initialPage: 100);
  Future<List<Map<String, Object?>>> fetchData(int index) async {
    return await getTaskByDate(int.parse(DateFormat('ddMMyy')
        .format(DateTime.now().add(Duration(days: index)))));
  }

  @override
  Widget build(BuildContext context) {
    int ctime = DateTime.now().hour * 60 + DateTime.now().minute;
    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemBuilder: (context, bindex) {
            return FutureBuilder<List<Map<String, Object?>>>(
              future: fetchData(bindex - 100),
              builder: (context, snapshot) {
                final index = bindex - 100;

                List<Map<String, Object?>> tasks = [];
                if (snapshot.hasData) {
                  final tmp = snapshot.data!;
                  for (final t in tmp) {
                    tasks.add(t);
                  }
                }
                

                List<Widget> wid = [];
                Map<String, Object?> min = {'start': 2000};
                int time = 0, mark = -1;

                while (tasks.isNotEmpty) {
                  min = {'start': 2000};
                  for (int i = 0; i < tasks.length; i++) {
                    if ((min['start'] as int) > (tasks[i]['start'] as int)) {
                      min = tasks[i];
                    }
                  }
                  mark = -1;
                  if (ctime >= time && ctime <= (min['start'] as int)) {
                    mark = ctime;
                  }
                  wid.add(EmptySpace(
                    startTime: time,
                    endTime: min['start'] as int,
                    marker: mark,
                  ));
                  time = min['end'] as int;
                  mark = -1;
                  if (ctime >= (min['start'] as int) && ctime <= time) {
                    mark = ctime;
                  }
                  wid.add(Task(
                    name: min['name'] as String,
                    startTime: min['start'] as int,
                    endTime: time,
                    description: min['description'] as String,
                    colour: Color(min['colour'] as int),
                    marker: mark,
                    date: int.parse(min['date'] as String),
                    onTap: () => setState(() {}),
                  ));
                  tasks.remove(min);
                }
                if (ctime >= time) mark = ctime;
                wid.add(
                    EmptySpace(startTime: time, endTime: 1440, marker: mark));

                return Stack(
                  children: [
                    ListView(
                      children: wid,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).viewPadding.top + 10),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()
                              .add(Duration(
                                  days:
                                      index))),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const AddTaskScreen();
                  })).then((_) => setState(() {}));
                },
              ),
            )),
      ],
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> { // very ugly
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedStartTime = TimeOfDay.now();
  TimeOfDay selectedEndTime = TimeOfDay.now();
  String name = '';
  Color colour = const Color(0xFF0047AB);
  String description = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    TextField(
                      onChanged: (value) {
                        name = value;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Task name',
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Select date'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selectedStartTime.format(context),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        showTimePicker(
                          context: context,
                          initialTime: selectedStartTime,
                        ).then((value) {
                          setState(() {
                            selectedStartTime = value!;
                          });
                        });
                      },
                      child: const Text('Select start time'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selectedEndTime.format(context),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        showTimePicker(
                          context: context,
                          initialTime: selectedEndTime,
                        ).then((value) {
                          setState(() {
                            selectedEndTime = value!;
                          });
                        });
                      },
                      child: const Text('Select end time'),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: (value) {
                        description = value;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // colour picker
                    ElevatedButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.black,
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: colour,
                                onColorChanged: (value) {
                                  setState(() {
                                    colour = value;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colour,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder()),
                      child: const Text('colour'),
                    ),
                    const SizedBox(height: 20),
                    if (name.isNotEmpty &&
                        toInt(selectedStartTime) < toInt(selectedEndTime))
                      ElevatedButton(
                        onPressed: () {
                          // add task to database
                          final TaskData taskData = TaskData(
                            name: name,
                            description: description,
                            colour: colour,
                            startTime: toInt(selectedStartTime),
                            endTime: toInt(selectedEndTime),
                            date: int.parse(
                                DateFormat('ddMMyy').format(selectedDate)),
                          );
                          insertTask(taskData);
                          Navigator.pop(context);
                        },
                        child: const Text('Add task'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Task extends StatelessWidget {
  final String name;
  final int startTime;
  final int endTime;
  final Color colour;
  final String description;
  final int marker;
  final int date;
  final Function onTap;
  const Task(
      {Key? key,
      required this.name,
      required this.date,
      required this.startTime,
      required this.endTime,
      required this.onTap,
      this.colour = const Color(0xFF6C4675),
      this.description = '',
      this.marker = -1}) // <- this is terrible, I hate it
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = (endTime - startTime).toDouble();
    List<Widget> box = [
      ElevatedButton(
          onPressed: () {
            TaskData d = TaskData(
              date: date,
              name: name,
              startTime: startTime,
              endTime: endTime,
              colour: colour,
              description: description,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskInfo(
                  task: d,
                ),
              ),
            ).then((value) => onTap());
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141414),
              padding: const EdgeInsets.all(0)),
          child: Row(
            children: [
              Container(
                width: 7,
                height: height,
                color: colour,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '${(startTime ~/ 60).toString().padLeft(2, '0')}:${(startTime % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '${(endTime ~/ 60).toString().padLeft(2, '0')}:${(endTime % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Text(
                name,
                style: TextStyle(color: Colors.white, fontSize: height / 3),
              ),
            ],
          )),
    ];
    if (marker != -1) {
      box.add(Column(
        children: [
          EmptySpace(
              startTime: startTime,
              endTime: ((marker - startTime > 3) ? marker - 3 : marker)),
          Container(
            width: double.infinity,
            height: 3,
            color: const Color(0xFF256D7B),
          ),
        ],
      ));
    }
    return SizedBox(
        height: height,
        child: Stack(
          children: box,
        ));
  }
}

class TaskData {
  final int date;
  final String name;
  final int startTime;
  final int endTime;
  final Color colour;
  final String description;
  const TaskData(
      {required this.date,
      required this.name,
      required this.startTime,
      required this.endTime,
      this.colour = const Color(0xFF6C4675),
      this.description = ''});

  Map<String, Object?> toMap() {
    return {
      'date': date,
      'name': name,
      'start': startTime,
      'end': endTime,
      'colour': colour.value,
      'description': description,
    };
  }
}


class EmptySpace extends StatelessWidget {
  final int startTime;
  final int endTime;
  final int marker;
  const EmptySpace({
    Key? key,
    required this.startTime,
    required this.endTime,
    this.marker = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> t = [
      SizedBox(
        height: (endTime - startTime).toDouble(), // add marker to Empty space
      ),
    ];
    if (marker != -1) {
      t.add(Column(
        children: [
          EmptySpace(
              startTime: startTime,
              endTime: ((marker - startTime > 3) ? marker - 3 : marker)),
          Container(
            width: double.infinity,
            height: 3,
            color: const Color(0xFF256D7B),
          ),
        ],
      ));
    }
    return Stack(
      children: t,
    );
  }
}

class TaskInfo extends StatelessWidget { // I'm going to add some very cool features here
  final TaskData task;
  const TaskInfo({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // dekete button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.delete),
                onPressed: () {
                  deleteTask(task);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
