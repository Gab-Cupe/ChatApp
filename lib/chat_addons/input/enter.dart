// ignore_for_file: library_private_types_in_public_api, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';

class EnterAwareTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Widget? suffixIcon;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const EnterAwareTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.suffixIcon,
    required this.onSend,
    this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  _EnterAwareTextFieldState createState() => _EnterAwareTextFieldState();
}

class _EnterAwareTextFieldState extends State<EnterAwareTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: widget.suffixIcon,
        ),
        onSubmitted: (_) {
          widget.onSend();
          // Mantener el foco después de enviar
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(_focusNode);
          });
        },
        onChanged: widget.onChanged,
      ),
    );
  }
}