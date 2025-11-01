import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.cyan,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => onTap(0),
              icon: Icon(
                Icons.home_outlined,
                color: currentIndex == 0 ? Colors.white : Colors.white70,
                size: 35,
              ),
            ),
            IconButton(
              onPressed: () => onTap(1),
              icon: Icon(
                Icons.work_outline_outlined,
                color: currentIndex == 1 ? Colors.white : Colors.white70,
                size: 35,
              ),
            ),
            IconButton(
              onPressed: () => onTap(2),
              icon: Icon(
                Icons.widgets_outlined,
                color: currentIndex == 2 ? Colors.white : Colors.white70,
                size: 35,
              ),
            ),
            IconButton(
              onPressed: () => onTap(3),
              icon: Icon(
                Icons.person_outline,
                color: currentIndex == 3 ? Colors.white : Colors.white70,
                size: 35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}