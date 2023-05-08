import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

//Handles the storage of data for units, preventing multiple queries of the same data, and also stores an array of UnitAttachments.
class Unit {
  late String name;
  List<String> stats = [];
  late int points = 0;
  late int index;
  int count = 0;
  int limit = 0;
  List<UnitAttachment> attachments = [];
  late String rules;
  int attachmentsize = 0;
  String attachmentString = "";
  late QueryDocumentSnapshot doc;

  Unit(this.doc, int nums, this.index) {
    for (int i = 1; i < nums; i++) {
      stats.add(doc['$i']);
    }
    name = doc['name'];
    points = int.parse(doc['points']);
    rules = doc['rules'];
    limit = doc['limit'];
    attachmentsize = doc['attachmentsize'];
  }

  @override
  String toString() {
    String retstring = '$name    points: $points\n';
    for (String i in stats) {
      retstring += i;
      retstring += ' ';
    }
    retstring += '\n Rules: $rules';
    retstring += '\n Attachments: $attachmentString';
    return retstring;
  }

  Unit clone() {
    return Unit(doc, stats.length, index);
  }

  StreamBuilder listAttachments(
      String gamename, String facname, String unitname, var db, int limit) {
    Stream<QuerySnapshot> uattachments = db
        .collection(
            "games/$gamename/factions/$facname/units/$unitname/attachments")
        .snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: uattachments,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Loading"));
        }
        final data = snapshot.data;
        return ListView.builder(
            itemCount: data?.size,
            itemBuilder: (BuildContext context, int index) {
              attachments.add(
                  UnitAttachment(data!.docs[index], attachmentsize, index));
              String attachname = attachments[index].name;
              return ListTile(
                  key: Key(attachname),
                  title: Text(attachments[index].toString()),
                  onTap: () => {
                        if (points + attachments[index].points <= limit)
                          {
                            points += attachments[index].points,
                            attachmentString += '$attachname ',
                          }
                      },
                  trailing: IconButton(
                    hoverColor: Colors.red,
                    splashRadius: 20,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      points -= attachments[index].points;
                      attachmentString.replaceFirst(attachname, '');
                      attachmentString.replaceFirst(',', '');
                    },
                  ));
            });
      },
    );
  }
}

//This class handles data for unit attachments and provides a toString for display.
class UnitAttachment {
  List<String> stats = [];
  late String name;
  int points = 0;
  late int index;
  late String rules;
  int count = 0;

  UnitAttachment(QueryDocumentSnapshot doc, int nums, this.index) {
    for (int i = 1; i <= nums; i++) {
      stats.add(doc['$i']);
    }
    //debugPrint("Out of UA for loop");
    name = doc['name'];
    points = int.parse(doc['points']);
    //debugPrint("Past UA points");
    rules = doc['rules'];
  }

  @override
  String toString() {
    String retstring = '$name  points: $points\n';
    for (String i in stats) {
      retstring += i;
      retstring += ' ';
    }
    retstring += '\n';
    retstring += 'Rules: $rules';
    return retstring;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ListDB',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const Nav(),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  //Variables needed to query the database and store list information.
  final String title;
  List<Widget> widgets = [];
  List<Unit> units = [];
  List<Unit> list = [];
  int numstats = 0;
  int points = 0;
  int limit = 0;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var db = FirebaseFirestore.instance;
  int currentState = 0;

  @override
  // This method is rerun every time setState is called
  //
  // The Flutter framework has been optimized to make rerunning build methods
  // fast, so that you can just rebuild anything that needs updating rather
  // than having to individually change instances of widgets.
  Widget build(BuildContext context) {
    if (currentState == 0) {
      //Base case, recreate from the starting point the game list, add it to the array.
      widget.widgets.add(buildGames());
      return widget.widgets[0];
    } else {
      //Display whichever widget is next, each setState will or decrement the state appropriately.
      return widget.widgets[currentState];
    }
  }

  //Builds the initial list of games using a querySnapshot.
  Widget buildGames() {
    final Stream<QuerySnapshot> games = db.collection('games').snapshots();

    return Scaffold(
      body: Column(children: <Widget>[
        //const Text(thing);
        const Text("Games"),
        SizedBox(
            height: 200,
            //Every Streambuilder for each Widget works the same way, checks snapshot for error, displays a brief loading message, then builds
            //the list it is meant to by iterating over each entry in the query.
            child: StreamBuilder<QuerySnapshot>(
                stream: games,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text("Loading"));
                  }
                  final data = snapshot.data;

                  return ListView.builder(
                    itemCount: data?.size,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                          child: ListTile(
                              key: Key(data?.docs[index]['name']),
                              title: Center(
                                  child: Text(data?.docs[index]['name'])),
                              onTap: () => {
                                    //advance to state 1 which is factions and add the factions to the widget list.
                                    //Passes the current game name to build the query in the following widget.
                                    setState(() {
                                      widget.widgets.add(viewFactions(
                                          data?.docs[index]['name']));
                                      currentState++;
                                      widget.numstats =
                                          data?.docs[index]['numstats'];
                                    })
                                  }));
                    },
                  );
                }))
      ]),
    );
  }

  //Builds the list of faction using the game selected by buildGames().
  Widget viewFactions(String gamename) {
    Stream<QuerySnapshot> factions =
        db.collection("games/$gamename/factions").snapshots();
    return Scaffold(
      body: Column(children: <Widget>[
        //const Text(thing);
        Text("Factions in $gamename \n"),
        SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
                stream: factions,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text("Loading"));
                  }
                  final data = snapshot.data;

                  return ListView.builder(
                    itemCount: data?.size,
                    itemBuilder: (BuildContext context, int index) {
                      //debugPrint(data?.docs[index]['name']);
                      return Center(
                          child: ListTile(
                              key: Key(data?.docs[index]['name']),
                              title: Center(
                                  child: Text(data?.docs[index]['name'])),
                              onTap: () => {
                                    //Advances state to display units, passing the gamename and faction name to build the next query.
                                    setState(() {
                                      widget.widgets.add(viewUnits(
                                          gamename, data?.docs[index]['name']));
                                      currentState++;
                                    })
                                  }));
                    },
                  );
                }))
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            //Resets the widget list completely and hard resets state to 0 to prevent some wonkiness.
            setState(() {
              widget.widgets = [];
              currentState = 0;
            });
          },
          label: const Text("Return to game selection"),
          icon: const Icon(Icons.arrow_back)),
    );
  }

  //Displays the list of units using data from both buildgames() and viewFactions().
  //Todo: Make this page responsive, currently not rebuilding when screen is rotated or page size changes.
  Widget viewUnits(String gamename, String facname) {
    Stream<QuerySnapshot> units =
        db.collection("games/$gamename/factions/$facname/units").snapshots();
    int stats = widget.numstats;
    return Scaffold(
      appBar: PreferredSize(
          preferredSize:
              Size.fromHeight((MediaQuery.of(context).size.height) / 20),
          child: AppBar(
            leadingWidth: 100,
            leading: TextField(
              decoration: const InputDecoration(hintText: 'Points Limit'),
              onSubmitted: (text) {
                setState(() {
                  widget.limit = int.parse(text);
                  updateListWidget(gamename, facname);
                });
              },
            ),
            title: Text("Points: ${widget.points}"),
            centerTitle: true,
          )),
      body: Column(children: <Widget>[
        Text("units in $facname\n"),
        Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
            child: SizedBox(
              height: ((MediaQuery.of(context).size.height) / 10) * 4,
              child: StreamBuilder<QuerySnapshot>(
                stream: units,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text("Loading"));
                  }
                  final data = snapshot.data;

                  return ListView.builder(
                      itemCount: data?.size,
                      itemBuilder: (BuildContext context, int index) {
                        //Creating the unit object and adding it to the array of units
                        widget.units.add(Unit(data!.docs[index], stats, index));
                        return Center(
                            child: ListTile(
                                key: Key(data.docs[index]['name']),
                                title: Center(
                                    child: RichText(
                                        //Color for the text suddenly became red without this line.
                                        selectionColor: Colors.black,
                                        text: TextSpan(
                                            text: widget.units[index]
                                                .toString()))),
                                onTap: () => {
                                      setState(() {
                                        addUnit(index);
                                        updateListWidget(gamename, facname);
                                      })
                                    }));
                      });
                },
              ),
            ),
          ),
        ),
        //This SizedBox is displaying the units in the list.
        const Text("Currently Selected Units"),
        Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
            child: SizedBox(
              height: ((MediaQuery.of(context).size.height) / 10) * 2.5,
              child: ListView.builder(
                itemCount: widget.list.length,
                itemBuilder: (BuildContext context, int index) {
                  return Center(
                      child: ListTile(
                    hoverColor: Colors.red,
                    title: Center(
                      child: RichText(
                          text: TextSpan(text: widget.list[index].toString())),
                    ),
                    //Removing the clicked unit from the list, above hover color is red as a warning.
                    onTap: () => {
                      setState(() {
                        removeUnit(index);
                        updateListWidget(gamename, facname);
                      })
                    },
                    //This button displays the unit's attachments.
                    trailing: IconButton(
                      hoverColor: const Color.fromARGB(255, 116, 116, 116),
                      splashRadius: 20,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: /*This method will display the unit's attachments*/
                          () => {
                        setState(() {
                          String unitName = widget.list[index].name;
                          showDialog(
                              context: context,
                              builder: (builder) => AlertDialog(
                                    content: Text("Attachments for $unitName"),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        child: const Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          updateListWidget(gamename, facname);
                                        },
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                100 *
                                                25,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        child: (widget.list[index]
                                            .listAttachments(gamename, facname,
                                                unitName, db, widget.limit)),
                                      )
                                    ],
                                  ));
                        })
                      },
                    ),
                  ));
                },
              ),
            ),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              widget.widgets.removeAt(2);
              currentState--;
              widget.list = [];
              widget.points = 0;
              widget.limit = 0;
              widget.units = [];
            });
          },
          backgroundColor: Colors.red,
          label: const Text(
              "Return to faction selection \n This will reset the list!"),
          icon: const Icon(Icons.arrow_back)),
    );
  }

  //Adds a unit to the list if it is within point threshold, meant to alert the user
  addUnit(int index) {
    if (widget.points + widget.units[index].points > widget.limit) {
      showDialog(
          context: context,
          builder: (builder) => AlertDialog(
                  content: const Text("Not enough points in the list!"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(builder).pop();
                      },
                      child: const Text("Click here to close"),
                    )
                  ]));
      return;
    } else if (widget.units[index].count + 1 > widget.units[index].limit &&
        widget.units[index].limit > 0) {
      int limit = widget.units[index].limit;
      showDialog(
          context: context,
          builder: (builder) => AlertDialog(
                  content: Text(
                      "Already at the limit of this unit, which is $limit"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(builder).pop();
                      },
                      child: const Text("Click here to close"),
                    )
                  ]));
      return;
    } else {
      widget.list.add(widget.units[index].clone());
      widget.points += widget.units[index].points;
      widget.units[index].count++;
    }
  }

  //Method used in the setState for the ontap that deletes a unit.
  removeUnit(int index) {
    widget.points -= widget.list[index].points;
    for (var element in widget.units) {
      if (element.name == widget.list[index].name) {
        element.count--;
      }
    }
    widget.list.removeAt(index);
  }

  //Simple method called to rebuild the view of the list after changes
  updateListWidget(gamename, facname) {
    widget.widgets.removeLast();
    widget.widgets.add(viewUnits(gamename, facname));
    widget.points = 0;
    for (int index = 0; index < widget.list.length; index++) {
      widget.points += widget.list[index].points;
    }
  }
}

/// Uses navigation rail to move between pages
class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int currentPage = 0;
  NavigationRailLabelType lType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double align = -1.0;

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [
      MyHomePage(
        title: 'title',
      ),
      const Center(
          child: Center(
              // ignore: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings
              child: Text("Select the game and then faction you would like" +
                  "to play, then in the points box enter the number of points you would like the list to be " +
                  "and press enter or return, and select units. If you add something that exceeds your limit you will be notified."))),
      const Center(child: Text("Feature in Progress"))
    ];
    return Scaffold(
        appBar: PreferredSize(
            preferredSize:
                Size.fromHeight((MediaQuery.of(context).size.height) / 20),
            child: AppBar(title: const Text("ListDB"), centerTitle: true)),
        bottomNavigationBar: NavigationBar(
            height: ((MediaQuery.of(context).size.height) / 10),
            backgroundColor: Colors.blueGrey,
            onDestinationSelected: (int index) {
              if (currentPage != index) {
                setState(() {
                  currentPage = index;
                });
              }
            },
            selectedIndex: currentPage,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'ListDB'),
              NavigationDestination(
                  icon: Icon(Icons.question_mark), label: 'How to use'),
              NavigationDestination(icon: Icon(Icons.edit), label: 'Edit DB')
            ]),
        body: content[currentPage]);
  }
}

///TODO: This entire widget
class AddtoDB extends StatefulWidget {
  const AddtoDB({super.key});

  @override
  State<AddtoDB> createState() => _AddtoDB();
}

///TODO: This entire widget
class _AddtoDB extends State<AddtoDB> {
  @override
  Widget build(BuildContext context) {
    var db = FirebaseFirestore.instance;
    return const Scaffold();
  }
}
