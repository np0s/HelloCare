import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>>? _suggestions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAISuggestions();
      if (response['success']) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(response['data']['suggestions']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?['message'] ?? 'Failed to load suggestions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isDietRelated(Map<String, dynamic> suggestion) {
    final type = (suggestion['type'] ?? '').toString().toLowerCase();
    final title = (suggestion['title'] ?? '').toString().toLowerCase();
    final description = (suggestion['description'] ?? '').toString().toLowerCase();
    
    return type == 'diet' || 
           title.contains('diet') || 
           title.contains('food') || 
           title.contains('nutrition') ||
           title.contains('meal') ||
           description.contains('diet') ||
           description.contains('food') ||
           description.contains('nutrition') ||
           description.contains('meal');
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return AppTheme.accentPink;
      default:
        return AppTheme.primaryGreen;
    }
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion) {
    final priority = suggestion['priority'] ?? 'low';
    final priorityColor = _getPriorityColor(priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor,
          radius: 20,
          child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                suggestion['title'] ?? 'Suggestion',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                (priority).toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              backgroundColor: priorityColor.withOpacity(0.2),
              labelStyle: TextStyle(color: priorityColor),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: AppTheme.primaryGreen,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            suggestion['description'] ?? 'No description available',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          if (suggestion['type'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Type: ${suggestion['type']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> suggestions, IconData icon) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...suggestions.map((suggestion) => _buildSuggestionTile(suggestion)),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> dietSuggestions = [];
    List<Map<String, dynamic>> otherSuggestions = [];

    if (_suggestions != null) {
      for (var suggestion in _suggestions!) {
        if (_isDietRelated(suggestion)) {
          dietSuggestions.add(suggestion);
        } else {
          otherSuggestions.add(suggestion);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('AI Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSuggestions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _suggestions == null || _suggestions!.isEmpty
                  ? const Center(
                      child: Text(
                        'No suggestions available',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Diet & Nutrition',
                            dietSuggestions,
                            Icons.restaurant,
                          ),
                          _buildSection(
                            'Other Suggestions',
                            otherSuggestions,
                            Icons.medical_services,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

