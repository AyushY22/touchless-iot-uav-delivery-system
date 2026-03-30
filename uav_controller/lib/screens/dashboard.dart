import 'package:flutter/material.dart';
import '../widgets/info_card.dart';
import 'package:firebase_database/firebase_database.dart';

final dbRef = FirebaseDatabase.instance.ref();

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // 🔷 UI STATES
  bool isGestureActive = false;
  bool isVoiceActive = false;

  // 🔷 FIREBASE DATA
  int battery = 0;
  double lat = 0;
  double lng = 0;
  int altitude = 0;
  int speed = 0;
  String status = "disconnected";

  // 🔷 COMMAND SEND
  void sendCommand(String command) {
    dbRef.child("commands").set({
      "action": command,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });
  }

  // 🔷 FIREBASE LISTENER
  @override
  void initState() {
    super.initState();

    dbRef.child("drone").onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data != null) {
        setState(() {
          // 🔋 Battery (telemetry se)
          battery = data["telemetry"]?["battery"] ?? 0;

          // 📍 Location
          lat = (data["location"]?["latitude"] ?? 0).toDouble();
          lng = (data["location"]?["longitude"] ?? 0).toDouble();

          // ✈ Altitude (z axis)
          altitude = data["telemetry"]?["z"] ?? 0;

          // 🚀 Speed (y axis assume)
          speed = data["telemetry"]?["y"] ?? 0;

          // 🔌 Status
          status = (data["status"] ?? "disconnected").toString().toLowerCase();
        });
      }
    });
  }

  // 🔷 GESTURE
  void _activateGesture() {
    setState(() => isGestureActive = true);

    sendCommand("gesture_mode");

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => isGestureActive = false);
      }
    });
  }

  // 🔷 VOICE
  void _activateVoice() {
    setState(() => isVoiceActive = true);

    sendCommand("voice_mode");

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => isVoiceActive = false);
      }
    });
  }

  // 🔷 TEXT COMMAND
  void sendTextCommand(String value) {
    sendCommand(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔷 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue,
            child: Row(
              children: [
                // LEFT: MENU
                const Icon(Icons.menu, color: Colors.white),

                // CENTER: TITLE
                const Expanded(
                  child: Center(
                    child: Text(
                      "UAV Controller",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // RIGHT: STATUS
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == "connected" ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == "connected" ? "CONNECTED" : "DISCONNECTED",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔷 BODY
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 800;

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: isMobile
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                );
              },
            ),
          ),

          // 🔷 FOOTER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.black,
            child: const Center(
              child: Text(
                "© 2026 UAV Controller",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📱 MOBILE VIEW
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _dataCards(),

          const SizedBox(height: 10),

          _mapBox(),

          const SizedBox(height: 10),

          _controls(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 💻 DESKTOP VIEW
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LEFT (DATA)
        Expanded(flex: 2, child: _dataCards()),

        const SizedBox(width: 10),

        // CENTER (MAP)
        Expanded(flex: 3, child: _mapBox()),

        const SizedBox(width: 10),

        // RIGHT (CONTROLS)
        Expanded(flex: 2, child: _controls()),
      ],
    );
  }

  // 🔷 DATA CARDS
  Widget _dataCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      children: [
        InfoCard(
          icon: Icons.battery_full,
          title: "Battery",
          value: "$battery%",
          color: Colors.green,
        ),
        InfoCard(
          icon: Icons.location_on,
          title: "Location",
          value: "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
          color: Colors.red,
        ),
        InfoCard(
          icon: Icons.flight,
          title: "Altitude",
          value: "$altitude m",
          color: Colors.blue,
        ),
        InfoCard(
          icon: Icons.speed,
          title: "Speed",
          value: "$speed m/s",
          color: Colors.orange,
        ),
      ],
    );
  }

  // 🗺️ MAP BOX (Placeholder)
  Widget _mapBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: Text("MAP (Live Drone Location)")),
    );
  }

  // 🎮 CONTROLS
  Widget _controls() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔷 GESTURE BUTTON
          ElevatedButton(
            onPressed: _activateGesture,
            child: const Text("Gesture"),
          ),

          const SizedBox(height: 10),

          // 🎥 VIDEO BOX WITH BORDER CHANGE
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGestureActive ? Colors.green : Colors.black,
                width: 3,
              ),
            ),
            child: const Center(child: Text("Camera Feed")),
          ),

          const SizedBox(height: 20),

          // 🎤 VOICE + MIC
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _activateVoice,
                child: const Text("Voice"),
              ),

              const SizedBox(width: 10),

              Icon(
                Icons.mic,
                size: 30,
                color: isVoiceActive ? Colors.green : Colors.black,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 🧾 MESSAGE BOX
          TextField(
            onSubmitted: (value) {
              sendCommand(value);
            },
            decoration: const InputDecoration(
              hintText: "Command will appear here...",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // 🎮 REMOTE (same as before)
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: ElevatedButton(
                    onPressed: () => sendCommand("takeoff"),
                    child: Text("Takeoff"),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: ElevatedButton(
                    onPressed: () => sendCommand("land"),
                    child: Text("Land"),
                  ),
                ),

                Center(
                  child: ElevatedButton(
                    onPressed: () => sendCommand("hover"),
                    child: Text("Hover"),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  left: 10,
                  child: ElevatedButton(
                    onPressed: () => sendCommand("left"),
                    child: Text("Left"),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  right: 10,
                  child: ElevatedButton(
                    onPressed: () => sendCommand("right"),
                    child: Text("Right"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
