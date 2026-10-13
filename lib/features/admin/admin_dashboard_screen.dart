import 'package:flutter/material.dart';

import 'manage_skills_screen.dart';
import 'manage_questions_screen.dart';
import 'manage_users_screen.dart';


class AdminDashboardScreen extends StatelessWidget {

  const AdminDashboardScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F6FA),


      appBar: AppBar(

        backgroundColor: const Color(0xFF6C63FF),

        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          children: [


            const Text(

              "Welcome Admin 👋",

              style: TextStyle(

                fontSize: 25,

                fontWeight: FontWeight.bold,

              ),

            ),


            const SizedBox(height: 30),



            _adminCard(

              context,

              Icons.school,

              "Manage Skills",

              const ManageSkillsScreen(),

            ),



            _adminCard(

              context,

              Icons.quiz,

              "Manage Questions",

              const ManageQuestionsScreen(),

            ),



            _adminCard(

              context,

              Icons.people,

              "Manage Users",

              const ManageUsersScreen(),

            ),


          ],

        ),

      ),

    );

  }





  Widget _adminCard(

      BuildContext context,

      IconData icon,

      String title,

      Widget screen,

      ) {


    return Container(

      margin: const EdgeInsets.only(bottom: 15),


      child: Card(

        elevation: 5,


        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(18),

        ),


        child: ListTile(


          leading: CircleAvatar(

            backgroundColor: const Color(0xFF6C63FF),

            child: Icon(

              icon,

              color: Colors.white,

            ),

          ),


          title: Text(

            title,

            style: const TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),


          trailing: const Icon(

            Icons.arrow_forward_ios,

          ),


          onTap: () {


            Navigator.push(

              context,

              MaterialPageRoute(

                builder: (_) => screen,

              ),

            );


          },

        ),

      ),

    );


  }

}