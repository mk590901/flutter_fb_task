import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'service_bloc.dart';
import 'foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeForegroundService();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServiceBloc(),
      child: MaterialApp(home: HomeScreen()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable the default behavior of the "back" button
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // If pop has already been executed, do nothing
        // Show the dialog box
        final result = await showDialog<String>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Application exit',
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
                content: Text(
                  'Choose one of app exit option:\n\t - Ignore: stay in application\n\t - Close: exit leaving service\n\t - Exit: stop service and exit',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                actions: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, 'ignore'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(40, 36),
                              textStyle: TextStyle(fontSize: 10),
                            ),
                            child: Text('Ignore'),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, 'close'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(40, 36),
                              textStyle: TextStyle(fontSize: 10),
                            ),
                            child: Text('Close'),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, 'exit'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(20, 36),
                              textStyle: TextStyle(fontSize: 10),
                            ),
                            child: Text('Exit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        );

        // Processing user selection
        await reaction(result, context);
        // For 'ignore' we do nothing, the dialog just closes
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Foreground Service App')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlocBuilder<ServiceBloc, ServiceState>(
                    builder: (context, state) {
                      return Text(
                        state.isServiceRunning
                            ? 'Service is Running'
                            : 'Service is Stopped',
                        style: TextStyle(fontSize: 20),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  BlocBuilder<ServiceBloc, ServiceState>(
                    builder: (context, state) {
                      return Text(
                        'Counter: ${state.counter}',
                        style: TextStyle(fontSize: 18),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  BlocBuilder<ServiceBloc, ServiceState>(
                    builder: (context, state) {
                      return Text(
                        'Numbers: ${state.numbers.map((n) => n.toStringAsFixed(2)).join(', ')}',
                        style: TextStyle(fontSize: 16),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter data to send',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  BlocBuilder<ServiceBloc, ServiceState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          Text(
                            'Last sent data: ${state.inputData}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              final String data = _controller.text.trim();
                              if (data.isNotEmpty) {
                                print('Button pressed, sending: $data');
                                context.read<ServiceBloc>().add(SendData(data));
                                _controller.clear(); // Uncomment to clear field
                              }
                            },
                            child: Text('Send Data to Service'),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              if (state.isServiceRunning) {
                                context.read<ServiceBloc>().add(StopService());
                              } else {
                                context.read<ServiceBloc>().add(StartService());
                              }
                            },
                            child: Text(
                              state.isServiceRunning
                                  ? 'Stop Service'
                                  : 'Start Service',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> reaction(String? result, BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    if (result == 'close') {
      await SystemNavigator.pop();
    } else if (result == 'exit') {
      if (context.mounted) {
        context.read<ServiceBloc>().add(StopService());
      }
      await SystemNavigator.pop();
    }
  }
}
