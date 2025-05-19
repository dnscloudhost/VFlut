import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';

class ConnectionButton extends StatelessWidget {
  final bool connected;
  final VoidCallback onPressed;

  const ConnectionButton({
    super.key,
    required this.connected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
          border: Border.all(
            color: connected ? Colors.redAccent : Colors.greenAccent,
            width: 8,
          ),
        ),
        child: Center(
          child: Icon(
            connected ? Icons.power_off : Icons.power,
            size: 64,
            color: connected ? Colors.redAccent : Colors.greenAccent,
          ),
          // برای Lottie به جای Icon از این استفاده کن:
          // child: Lottie.asset(
          //   connected ? 'assets/lottie/power_off.json' : 'assets/lottie/power_on.json',
          //   width: 120, height: 120, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
