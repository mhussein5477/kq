import 'package:flutter/material.dart';

class CustomTopBar extends StatelessWidget {
  const CustomTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),

          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Kenya Airways',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Pride of Africa',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Spacer(),
        // NOTIFICATION ICON ON FAR RIGHT
        // IconButton(
        //   onPressed: () {},
        //   icon: const Icon(
        //     Icons.notifications_outlined,
        //     color: Colors.black,
        //     size: 26,
        //   ),
        // ),
      ],
    );
  }
}
