import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/ai_summary_display.dart';

class AISummaryPage extends StatefulWidget {
  const AISummaryPage({super.key});

  @override
  State<AISummaryPage> createState() => _AISummaryPageState();
}

class _AISummaryPageState extends State<AISummaryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAISummary();
      print('AI Summary Response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('AI Summary Data type: ${data.runtimeType}');
        print('AI Summary Data: $data');
        
        // Process the data - handle both string and Map formats
        Map<String, dynamic> processedData;
        
        if (data is String) {
          // If data is a string, try to parse it as JSON
          try {
            final decoded = json.decode(data);
            processedData = decoded is Map ? Map<String, dynamic>.from(decoded) : {'overallSummary': data};
          } catch (e) {
            print('Failed to parse JSON string: $e');
            // If it's not valid JSON, treat as plain text summary
            processedData = {
              'overallSummary': data,
              'findings': [],
              'priorityEmoji': '✅',
            };
          }
        } else if (data is Map) {
          processedData = Map<String, dynamic>.from(data);
        } else {
          print('Unexpected data type: ${data.runtimeType}');
          throw Exception('Unexpected data type: ${data.runtimeType}');
        }

        print('Processed data keys: ${processedData.keys.toList()}');

        // Check if it's the new structured format (has findings or overallSummary)
        if (processedData.containsKey('findings') || processedData.containsKey('overallSummary')) {
          // New structured format - normalize all fields
          final findings = processedData['findings'];
          final findingsList = findings is List 
              ? findings.map((f) => f is Map ? Map<String, dynamic>.from(f) : {}).toList()
              : [];
          
          setState(() {
            _summaryData = {
              'schemaVersion': processedData['schemaVersion']?.toString() ?? 'v1.0',
              'reportId': processedData['reportId'],
              'reportDate': processedData['reportDate']?.toString(),
              'confidence': processedData['confidence'] is num ? processedData['confidence'] : 0.0,
              'confidenceBreakdown': processedData['confidenceBreakdown'] is Map 
                  ? Map<String, dynamic>.from(processedData['confidenceBreakdown'])
                  : {
                      'legibility': 0.0,
                      'valueParsing': 0.0,
                      'rangeParsing': 0.0,
                      'unitParsing': 0.0,
                      'mappingToTestName': 0.0,
                    },
              'findings': findingsList,
              'identifiedPanels': processedData['identifiedPanels'] is List
                  ? (processedData['identifiedPanels'] as List).map((e) => e.toString()).toList()
                  : [],
              'priorityEmoji': processedData['priorityEmoji']?.toString() ?? '✅',
              'overallSummary': processedData['overallSummary']?.toString() ?? '',
              'criticalSummary': processedData['criticalSummary']?.toString() ?? '',
              'suggestedLifestyleFocus': processedData['suggestedLifestyleFocus'] is List
                  ? (processedData['suggestedLifestyleFocus'] as List).map((e) => e.toString()).toList()
                  : [],
              'educationSearchTerms': processedData['educationSearchTerms'] is List
                  ? (processedData['educationSearchTerms'] as List).map((e) => e.toString()).toList()
                  : [],
              'parsingNotes': processedData['parsingNotes']?.toString() ?? '',
              'phiRedacted': processedData['phiRedacted'] == true,
              'generatedAt': processedData['generatedAt']?.toString(),
              'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : null,
            };
            _isLoading = false;
          });
          print('Summary data set successfully');
        } else if (processedData.containsKey('summary')) {
          // Old format - convert to new format structure
          setState(() {
            _summaryData = {
              'overallSummary': processedData['summary']?.toString() ?? '',
              'findings': [],
              'priorityEmoji': '✅',
              'generatedAt': processedData['generatedAt']?.toString(),
              'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : null,
            };
            _isLoading = false;
          });
        } else {
          print('Invalid response format - no findings or summary field');
          setState(() {
            _error = 'Invalid response format: Missing required fields';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = response['error']?['message']?.toString() ?? 'Failed to load summary';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading AI summary: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('AI Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
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
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSummary,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _summaryData == null
                  ? const Center(child: Text('No summary data available'))
                  : AISummaryDisplay(summaryData: _summaryData!),
    );
  }
}

