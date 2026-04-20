import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MultimediaScreen.dart';
import 'cooking_time_picker.dart';

class EditRecipeScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> recipeData;

  const EditRecipeScreen({
    super.key,
    required this.docId,
    required this.recipeData,
  });

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ingCtrl;
  late TextEditingController _stepsCtrl;

  late String _cookingTime;
  late String _imageUrl;
  bool _isSaving   = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.recipeData['name']);
    _descCtrl    = TextEditingController(text: widget.recipeData['description']);
    _ingCtrl     = TextEditingController(text: widget.recipeData['ingredients']);
    _stepsCtrl   = TextEditingController(text: widget.recipeData['steps']);
    _cookingTime = widget.recipeData['time'] ?? '';
    _imageUrl    = widget.recipeData['imageUrl'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ingCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('recipes').doc(widget.docId)
          .update({
        'name':        _nameCtrl.text.trim(),
        'time':        _cookingTime,
        'description': _descCtrl.text.trim(),
        'ingredients': _ingCtrl.text.trim(),
        'steps':       _stepsCtrl.text.trim(),
      });
      if (!mounted) return;
      _snack('Recipe updated ✓');
      Navigator.pop(context);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete Recipe'),
        content: Text('Delete "${_nameCtrl.text}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('recipes').doc(widget.docId).delete();
      if (!mounted) return;
      _snack('Recipe deleted');
      Navigator.pop(context);
    } catch (e) {
      _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _openMultimedia() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MultimediaScreen(
        docId:      widget.docId,
        recipeData: {...widget.recipeData, 'name': _nameCtrl.text},
      ),
    ));
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        maxLines:   maxLines,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
          filled:     true,
          fillColor:  theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:   BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Edit Recipe',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isDeleting ? null : _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _imageUrl,
                height: 200,
                width:  double.infinity,
                fit:    BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color:  Colors.grey.shade200,
                  child:  const Center(
                    child: Icon(Icons.image_not_supported,
                        size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Video & Audio button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMultimedia,
                icon:  const Icon(Icons.perm_media_outlined),
                label: const Text('Manage Video & Audio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side:    BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:   RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _field('Recipe Name',  _nameCtrl),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CookingTimePicker(
                initialValue: _cookingTime,
                onChanged: (v) => setState(() => _cookingTime = v),
              ),
            ),

            _field('Description',  _descCtrl,  maxLines: 3),
            _field('Ingredients',  _ingCtrl,   maxLines: 4),
            _field('Steps',        _stepsCtrl, maxLines: 6),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Changes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}