import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String)? onChanged;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search',
    this.onChanged,
    this.controller,
    required Null Function() onClear,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButton);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateClearButton() {
    setState(() {
      _showClear = _controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        cursorColor: Colors.grey.shade500,
        controller: _controller,
        onChanged: widget.onChanged,
        style: GoogleFonts.poppins(fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon:
              _showClear
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                    onPressed: () => _controller.clear(),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }
}
