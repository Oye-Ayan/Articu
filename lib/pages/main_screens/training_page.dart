import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/my_button.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  //function to show dialog box
void Betaversion_showDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: Text('Beta Version'),
      content: Text('Beta version. Complete Module is not available at the moment.',),
      actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                child: Text('OK', style: TextStyle(color: Colors.blue),),
              ),
            ],
          );         
        },
      );
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Daily practice',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              Betaversion_showDialog();
              // Handle info button
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.blue[700],
                      child: Text(
                        '01',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: CircleAvatar(
                        radius: 25.r,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: 18.sp,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View All',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                   var titles = [
                    "Introduction",
                    "Flexible Rate Introduction",
                    "Syllable Counting Practice",
                    "Flexible Rate Technique",
                    "Flexible Rate Practice - Modelling",
                    "ArticuliCare Journey",
                    "Conclusion"
                  ];
                  var times = [
                    "3 mins",
                    "2 mins",
                    "2 mins",
                    "2 mins",
                    "3 mins",
                    "2 mins",
                    "1 min"
                  ];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.card_giftcard, color: Colors.blue.shade700),
                    ),
                    title: Text(
                      titles[index],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                        color: index == 0 ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      times[index],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    trailing: Icon(
                      index == 0 ? Icons.play_circle_outline : null,
                      color: Colors.blue,
                      size: 24.sp,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: MyButton(
                onTap: () {
                  Betaversion_showDialog();
                },
                text: 'Start Practice',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
