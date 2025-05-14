import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'service_bloc.dart';
import 'foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeForegroundService();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServiceBloc(),
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foreground Service App')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BlocBuilder<ServiceBloc, ServiceState>(
                  builder: (context, state) {
                    return Text(
                      state.isServiceRunning ? 'Service is Running' : 'Service is Stopped',
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
                            final data = _controller.text.trim();
                            if (data.isNotEmpty) {
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
                          child: Text(state.isServiceRunning ? 'Stop Service' : 'Start Service'),
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
    );
  }
}
