import 'package:flutter/material.dart';


//githubtest
void main() {
  runApp(const MyApp());

  class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: Text("깃허브 협업 ... 안녕하세요 ! 이것은 저의 마지막 commit & push 시도 입니다." ),),
  );
  }
  }
}
