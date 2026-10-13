import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  bool importing = false;

  final List<String> categories = [
    'All',
    'AI',
    'Artificial Intelligence',
    'Data Science',
    'Cybersecurity',
    'Cyber Security',
    'English Speaking',
    'Flutter',
    'Web Development',
    'web',
    'Web',
    'SQL',
    'Python',
    'JavaScript',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String getCellValue(dynamic cell) {
    if (cell == null) return '';

    try {
      String value = cell.toString();
      value = value.trim();
      if (value.isEmpty || value == 'null' || value == 'Null') {
        return '';
      }
      return value;
    } catch (e) {
      return '';
    }
  }

  String extractCorrectAnswer(String optionD) {
    if (optionD.isEmpty) return '';

    try {
      final trimmed = optionD.trim();
      if (trimmed.isEmpty) return '';

      final lastChar = trimmed[trimmed.length - 1].toUpperCase();
      if (['A', 'B', 'C', 'D'].contains(lastChar)) {
        return lastChar;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ✅ IMPORT EXCEL - Web + Android Compatible (Bina dart:io ke)
  Future<void> importExcelQuestions() async {
    try {
      print('🚀 Starting Excel import...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) {
        print('⚠️ User cancelled');
        return;
      }

      setState(() {
        importing = true;
      });

      // ✅ Web + Android dono par kaam karega
      final Uint8List? bytes = result.files.single.bytes;

      if (bytes == null) {
        throw Exception('Could not read the selected Excel file.');
      }

      print('📄 File size: ${bytes.length} bytes');

      final excel = Excel.decodeBytes(bytes);

      print('✅ Excel decoded successfully');

      if (excel.tables.isEmpty) {
        throw Exception('No sheet found in the Excel file.');
      }

      final sheetName = excel.tables.keys.first;
      print('📊 Sheet name: $sheetName');

      final sheet = excel.tables[sheetName];
      if (sheet == null) {
        throw Exception('Could not open sheet.');
      }

      final rows = sheet.rows;
      print('📊 Total rows: ${rows.length}');

      if (rows.length <= 1) {
        throw Exception('No questions found. The file should have a header row and data rows.');
      }

      int added = 0;
      int skipped = 0;

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];

          if (row == null || row.isEmpty) {
            skipped++;
            continue;
          }

          while (row.length < 8) {
            row.add(null);
          }

          final question = getCellValue(row[0]);
          final category = getCellValue(row[1]);
          final optionA = getCellValue(row[2]);
          final optionB = getCellValue(row[3]);
          final optionC = getCellValue(row[4]);
          final optionD = getCellValue(row[5]);
          final correctAnswerFromCol = getCellValue(row[6]);
          final xpText = getCellValue(row[7]);

          if (question.isEmpty &&
              category.isEmpty &&
              optionA.isEmpty &&
              optionB.isEmpty &&
              optionC.isEmpty &&
              optionD.isEmpty) {
            skipped++;
            continue;
          }

          if (i <= 3) {
            print('📋 Row $i:');
            print('   Question: "$question"');
            print('   Category: "$category"');
            print('   Option A: "$optionA"');
            print('   Option B: "$optionB"');
            print('   Option C: "$optionC"');
            print('   Option D: "$optionD"');
            print('   XP: "$xpText"');
          }

          String correctAnswer = '';
          if (correctAnswerFromCol.isNotEmpty) {
            final cleaned = correctAnswerFromCol.toUpperCase().trim();
            if (['A', 'B', 'C', 'D'].contains(cleaned)) {
              correctAnswer = cleaned;
            }
          }

          if (correctAnswer.isEmpty) {
            correctAnswer = extractCorrectAnswer(optionD);
          }

          if (question.isEmpty ||
              category.isEmpty ||
              optionA.isEmpty ||
              optionB.isEmpty ||
              optionC.isEmpty ||
              optionD.isEmpty ||
              correctAnswer.isEmpty) {
            skipped++;
            continue;
          }

          if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
            skipped++;
            continue;
          }

          final validCategories = categories.sublist(1);
          if (!validCategories.contains(category)) {
            skipped++;
            continue;
          }

          final xp = int.tryParse(xpText) ?? 10;

          try {
            final duplicateQuery = await _firestore
                .collection('questions')
                .where('question', isEqualTo: question)
                .limit(1)
                .get();

            if (duplicateQuery.docs.isNotEmpty) {
              skipped++;
              continue;
            }
          } catch (dbError) {
            print('⚠️ Duplicate check error: $dbError');
          }

          try {
            await _firestore.collection('questions').add({
              'question': question,
              'category': category,
              'optionA': optionA,
              'optionB': optionB,
              'optionC': optionC,
              'optionD': optionD,
              'correctAnswer': correctAnswer,
              'xp': xp,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            added++;
            print('✅ Added question $i: $question');

          } catch (dbError) {
            print('❌ DB error: $dbError');
            skipped++;
            continue;
          }

        } catch (rowError) {
          print('❌ Error row $i: $rowError');
          skipped++;
          continue;
        }
      }

      if (!mounted) return;

      setState(() {
        importing = false;
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              '✅ $added questions added.\n\n'
                  '⚠️ $skipped questions skipped.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      print('❌ Import failed: $e');
      if (!mounted) return;
      setState(() {
        importing = false;
      });
      showMessage('Import failed: ${e.toString()}');
    }
  }

  Future<void> deleteQuestion(String id) async {
    try {
      await _firestore.collection('questions').doc(id).delete();
      if (!mounted) return;
      showMessage('Question deleted');
    } catch (e) {
      showMessage('Error: $e');
    }
  }

  void showDeleteDialog(String id, String question) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Question?'),
          content: Text('"$question"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await deleteQuestion(id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void openQuestionForm({
    String? id,
    Map<String, dynamic>? data,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionFormScreen(
          questionId: id,
          questionData: data,
          categories: categories.sublist(1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        centerTitle: true,
        title: const Text(
          'Manage Questions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        onPressed: importing ? null : () => openQuestionForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
      body: Column(
        children: [
          // ✅ IMPORT EXCEL BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: importing ? null : importExcelQuestions,
                icon: importing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.upload_file),
                label: Text(
                  importing ? 'Importing...' : 'Import from Excel',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ CATEGORY FILTER
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ✅ QUESTIONS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('questions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final search = searchController.text.trim().toLowerCase();

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final question = (data['question'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();

                  final matchesSearch = search.isEmpty || question.contains(search);
                  final matchesCategory = selectedCategory == 'All' || category == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No questions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final question = data['question'] ?? '';
                    final category = data['category'] ?? '';
                    final xp = data['xp'] ?? 10;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.toString(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(category.toString()),
                                  avatar: const Icon(Icons.category, size: 16),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                                  label: Text('$xp XP'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    openQuestionForm(
                                      id: doc.id,
                                      data: data,
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    showDeleteDialog(
                                      doc.id,
                                      question.toString(),
                                    );
                                  },
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================
// QUESTION FORM SCREEN
// ================================================
class QuestionFormScreen extends StatefulWidget {
  final String? questionId;
  final Map<String, dynamic>? questionData;
  final List<String> categories;

  const QuestionFormScreen({
    super.key,
    this.questionId,
    this.questionData,
    required this.categories,
  });

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final questionController = TextEditingController();
  final optionAController = TextEditingController();
  final optionBController = TextEditingController();
  final optionCController = TextEditingController();
  final optionDController = TextEditingController();
  final xpController = TextEditingController();

  String? category;
  String? correctAnswer;

  bool saving = false;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    final data = widget.questionData;

    if (data != null) {
      questionController.text = data['question'] ?? '';
      optionAController.text = data['optionA'] ?? '';
      optionBController.text = data['optionB'] ?? '';
      optionCController.text = data['optionC'] ?? '';
      optionDController.text = data['optionD'] ?? '';
      xpController.text = (data['xp'] ?? 10).toString();
      category = data['category'];
      correctAnswer = data['correctAnswer'];
    } else {
      xpController.text = '10';
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    xpController.dispose();
    super.dispose();
  }

  Future<void> saveQuestion() async {
    if (_formKey.currentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form is not ready')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (correctAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the correct answer')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final questionData = <String, dynamic>{
        'question': questionController.text.trim(),
        'category': category,
        'optionA': optionAController.text.trim(),
        'optionB': optionBController.text.trim(),
        'optionC': optionCController.text.trim(),
        'optionD': optionDController.text.trim(),
        'correctAnswer': correctAnswer,
        'xp': int.tryParse(xpController.text.trim()) ?? 10,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.questionId == null) {
        questionData['createdAt'] = FieldValue.serverTimestamp();
        await firestore.collection('questions').add(questionData);
      } else {
        await firestore
            .collection('questions')
            .doc(widget.questionId)
            .update(questionData);
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.questionId == null
                ? 'Question added successfully'
                : 'Question updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: Text(
          widget.questionId == null ? 'Add Question' : 'Edit Question',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Question
              field('Question', questionController, maxLines: 3),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: widget.categories.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    category = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Select category';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Options
              field('Option A', optionAController),
              field('Option B', optionBController),
              field('Option C', optionCController),
              field('Option D', optionDController),

              const SizedBox(height: 15),

              // Correct Answer Dropdown
              DropdownButtonFormField<String>(
                value: correctAnswer,
                decoration: InputDecoration(
                  labelText: 'Correct Answer',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Option A')),
                  DropdownMenuItem(value: 'B', child: Text('Option B')),
                  DropdownMenuItem(value: 'C', child: Text('Option C')),
                  DropdownMenuItem(value: 'D', child: Text('Option D')),
                ],
                onChanged: (value) {
                  setState(() {
                    correctAnswer = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Select correct answer';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // XP
              field('XP', xpController),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : saveQuestion,
                  icon: saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Saving...' : 'Save Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}