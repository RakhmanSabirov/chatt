import 'package:chat_app/core/colors.dart';
import 'package:flutter/material.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Чаты", style: TextStyle(fontSize: 32, color: Colors.black)),
            SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.fieldColor,
                hintText: "Поиск",
                hintStyle: TextStyle(color: AppColors.hintColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 24),
            Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: 10, // Примерное количество чатов
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text("Имя Фамилия $index"),
                    onTap: () {
                      // TODO: Добавить переход в чат
                    },
                  );
                },
                separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
