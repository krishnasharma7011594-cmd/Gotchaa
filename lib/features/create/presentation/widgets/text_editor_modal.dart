import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextEditorModal extends StatefulWidget {
  const TextEditorModal({super.key, this.initialText, this.initialColor});
  final String? initialText;
  final Color? initialColor;

  @override
  State<TextEditorModal> createState() => _TextEditorModalState();
}

class _TextEditorModalState extends State<TextEditorModal> {
  late TextEditingController _controller;
  late Color _selectedColor;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _selectedColor = widget.initialColor ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, {
                        'text': _controller.text,
                        'color': _selectedColor,
                      }),
                      child: Text('Done',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _selectedColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type something...',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ),

              // Color Picker
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final color = _colors[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
