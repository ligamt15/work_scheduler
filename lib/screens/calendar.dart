import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
User? user = _auth.currentUser;
Event? selectedEvent;
Event? _selectedEvent;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('workers').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          List<Map<String, dynamic>> workDates =
              List<Map<String, dynamic>>.from(snapshot.data!['workDate']);

          List<Event> events = workDates.map((date) {
            return Event(
              day: date['Day'],
              month: date['Month'],
              year: date['Year'],
              type: date['Event'], // может быть null
            );
          }).toList();

          Map<String, List<Event>> eventMap = {};
          for (var event in events) {
            final eventDate = DateTime(
              event.year,
              event.month,
              event.day,
            );

            final dateKey = formatDate(eventDate);
            if (eventMap[dateKey] != null) {
              eventMap[dateKey]!.add(event);
            } else {
              eventMap[dateKey] = [event];
            }
          }

          return Column(
            children: [
              TableCalendar(
                holidayPredicate: (day) {
                  // Weekends and days with no events
                  final dateKey = formatDate(day);
                  return day.weekday >= 6 || eventMap[dateKey] == null;
                },
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;

                    List<Event> selectedEvents =
                        _getEventsForDay(selectedDay, eventMap);
                    _selectedEvent =
                        selectedEvents.isNotEmpty ? selectedEvents.first : null;
                  });

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Select Event'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _storeEventInFirestore(
                                        selectedDay, 'Working Day')
                                    .then((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Event added to the calendar.'),
                                      ),
                                    );
                                    setState(() {
                                      _selectedDay =
                                          null; // Clear the selection
                                    });
                                    Navigator.pop(context);
                                  }
                                });
                              },
                              child: const Text('Working Day'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _storeEventInFirestore(
                                        selectedDay, 'Could be a Working Day')
                                    .then((_) {
                                  if (mounted) {
                                    setState(() {
                                      _calendarKey = GlobalKey();
                                    });
                                    Navigator.pop(context);
                                  }
                                });
                              },
                              child: const Text('Could be a Working Day'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                eventLoader: (day) {
                  final dateKey = formatDate(day);
                  return eventMap[dateKey] ?? [];
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _markerColorSelected(
                        _selectedEvent), // Используйте цвет выбранного события
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: _buildEventsMarker(date, events),
                      );
                    }
                    return Container();
                  },
                  holidayBuilder: (context, day, focusedDay) {
                    final dateKey = formatDate(day);

                    if (eventMap[dateKey] == null) {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(139, 194, 194, 194),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle().copyWith(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontSize: 12.0,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final dateKey = formatDate(day);
                    if (eventMap[dateKey] != null) {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _markerColor(eventMap[dateKey]![
                              0]), // Use the first event for color
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle().copyWith(
                            color: Colors.white,
                            fontSize: 12.0,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Event> _getEventsForDay(
      DateTime day, Map<String, List<Event>> eventMap) {
    final dateKey = formatDate(day);

    return eventMap[dateKey] ?? [];
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }
}

class Event {
  final int day;
  final int month;
  final int year;
  final String type;

  Event({
    required this.day,
    required this.month,
    required this.year,
    required this.type,
  });

  @override
  String toString() {
    return 'Event on ${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}: $type';
  }
}

Widget _buildEventsMarker(DateTime date, List events) {
  return Container(
    alignment: Alignment.topLeft,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _markerColor(events[0]), // Use the first event for color
      ),
    ),
  );
}

Color _markerColor(Event event) {
  switch (event.type) {
    case 'Working Day':
      return Colors.green;
    case 'Could be a Working Day':
      return const Color.fromARGB(255, 255, 48, 117);
    default:
      return Colors.blue;
  }
}

Color _markerColorSelected(Event? event) {
  switch (event?.type) {
    case 'Working Day':
      return Colors.green;
    case 'Could be a Working Day':
      return const Color.fromARGB(255, 255, 48, 117);
    default:
      return Colors.grey;
  }
}

Future<void> _storeEventInFirestore(DateTime date, String event) async {
  try {
    await FirebaseFirestore.instance
        .collection('workers')
        .doc(user?.uid)
        .update({
      'workDate': FieldValue.arrayUnion([
        {
          'Year': date.year,
          'Month': date.month,
          'Day': date.day,
          'Event': event
        }
      ])
    });
  } catch (e) {
    print('Failed to add event: $e');
  }
}
