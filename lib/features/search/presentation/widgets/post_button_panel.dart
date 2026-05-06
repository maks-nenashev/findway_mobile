import 'package:flutter/material.dart';

class PostButtonPanel extends StatelessWidget {
  final Map<String, dynamic> tr;
  final VoidCallback onCommentTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const PostButtonPanel({
    super.key,
    required this.tr,
    required this.onCommentTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Кнопка назад
          _actionButton(
            Icons.arrow_back, 
            Colors.white, 
            () => Navigator.pop(context), 
            bgColor: const Color(0xFF0A0E14)
          ),
          const SizedBox(width: 12),
          
          // Email (пока заглушка)
          _actionButton(Icons.alternate_email, Colors.cyan, () => debugPrint("Email Click")),
          const SizedBox(width: 12),
          
          // Комментарии
          _actionButton(Icons.chat_bubble_outline, Colors.orange, onCommentTap),
          const SizedBox(width: 12),
          
          // Редактирование
          _actionButton(Icons.edit_outlined, Colors.blueAccent, onEditTap),
          const SizedBox(width: 12),
          
          // Удаление
          _actionButton(Icons.delete_outline, Colors.redAccent, onDeleteTap),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: bgColor ?? color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}