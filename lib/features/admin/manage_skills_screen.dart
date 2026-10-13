import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSkillsScreen extends StatefulWidget {
  const ManageSkillsScreen({super.key});

  @override
  State<ManageSkillsScreen> createState() => _ManageSkillsScreenState();
}

class _ManageSkillsScreenState extends State<ManageSkillsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController =
  TextEditingController();
  final TextEditingController iconController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    iconController.dispose();
    super.dispose();
  }

  Future<void> addSkill() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final icon = iconController.text.trim();

    if (name.isEmpty || description.isEmpty || icon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    await _firestore.collection('skills').add({
      'name': name,
      'description': description,
      'icon': icon,
    });

    nameController.clear();
    descriptionController.clear();
    iconController.clear();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skill added successfully'),
      ),
    );
  }

  Future<void> updateSkill(String id) async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final icon = iconController.text.trim();

    if (name.isEmpty || description.isEmpty || icon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    await _firestore.collection('skills').doc(id).update({
      'name': name,
      'description': description,
      'icon': icon,
    });

    nameController.clear();
    descriptionController.clear();
    iconController.clear();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skill updated successfully'),
      ),
    );
  }

  Future<void> deleteSkill(String id) async {
    await _firestore.collection('skills').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skill deleted successfully'),
      ),
    );
  }

  void showSkillDialog({
    String? id,
    String? name,
    String? description,
    String? icon,
  }) {
    nameController.text = name ?? '';
    descriptionController.text = description ?? '';
    iconController.text = icon ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            id == null ? 'Add Skill' : 'Edit Skill',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon / Emoji',
                    hintText: '🤖',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.clear();
                descriptionController.clear();
                iconController.clear();

                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (id == null) {
                  addSkill();
                } else {
                  updateSkill(id);
                }
              },
              child: Text(
                id == null ? 'Add' : 'Update',
              ),
            ),
          ],
        );
      },
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
          'Manage Skills',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        onPressed: () {
          showSkillDialog();
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('skills').snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No skills found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final skills = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: skills.length,

            itemBuilder: (context, index) {
              final skill = skills[index];

              final data =
              skill.data() as Map<String, dynamic>;

              final String name =
                  data['name'] ?? 'No name';

              final String description =
                  data['description'] ?? 'No description';

              final String icon =
                  data['icon'] ?? '📚';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),

                child: Card(
                  elevation: 3,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                      const Color(0xFF6C63FF),

                      child: Text(
                        icon,
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),

                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding:
                      const EdgeInsets.only(top: 5),
                      child: Text(
                        description,
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF6C63FF),
                          ),
                          onPressed: () {
                            showSkillDialog(
                              id: skill.id,
                              name: name,
                              description: description,
                              icon: icon,
                            );
                          },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text(
                                    'Delete Skill',
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "$name"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          dialogContext,
                                        );
                                      },
                                      child: const Text(
                                        'Cancel',
                                      ),
                                    ),
                                    ElevatedButton(
                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.red,
                                        foregroundColor:
                                        Colors.white,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(
                                          dialogContext,
                                        );

                                        await deleteSkill(
                                          skill.id,
                                        );
                                      },
                                      child: const Text(
                                        'Delete',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}