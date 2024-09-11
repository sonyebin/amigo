import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // provider 사용
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';



//githubtest
void main() {
  runApp( ChangeNotifierProvider(
    create: (c) => Store1(),
    child: MaterialApp(
      //theme: style.theme,
        home: const MyApp()
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          body: [Home(), Community(), My()][context.watch<Store1>().tab],
          bottomNavigationBar: BottomNavigationBar(
            showUnselectedLabels: false,
            showSelectedLabels: false,
            unselectedItemColor: Colors.grey,
            selectedItemColor: Colors.black,

            onTap: (i){context.read<Store1>().changePage(i);},
            currentIndex: context.watch<Store1>().tab,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.text_snippet_outlined), label: 'community'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My')],
          ),
        )
    );
  }
}

// state 보관함... 일단 1개만 사용... 나중에 분리하기
class Store1 extends ChangeNotifier {
  var tab = 0;
  var post = [];
  var content;
  var likeColor = Colors.grey;
  var userImage;

  changePage(i) {
    tab = i;
    notifyListeners(); // state 사용 중인 위젯 자동 재렌더링
  }

  addPost(){
    // null일 때의 처리 필요. 현재는 아무것도 입력 안 하고 발행 시 null이라고 발행됨
    // 추후에 id 같은 거도 고유하게 설정해야 할 듯함 로그인 등 활용
    var myData = {'id':4, /* 일단 이미지제외 'image':userImage*/ 'likes':423, 'date': 'July 25',
      'content': content, 'liked': false, 'user':'yes_empty'};
    post.insert(0, myData);
    notifyListeners();
  }

  setUserContent(text){
    content = text;
  }

  addLike(i){
    if(post[i]['liked']== false){
      post[i]['liked'] = true;
      post[i]['likes'] += 1;
      likeColor = Colors.red;
    } else {
      post[i]['liked'] = false;
      post[i]['likes'] -= 1;
      likeColor = Colors.grey;
    }
    notifyListeners();
  }
}

// 홈 위젯
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('아직 아무것도...');
  }
}

// 글들 띄우는 위젯
class Community extends StatelessWidget {
  const Community({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(onPressed: (){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Upload()),
        );
      }, icon: Icon(Icons.add_box_outlined))],),
      body: ListView.builder(
          itemCount: context.watch<Store1>().post.length,
          itemBuilder: (c, i){
            return Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.person_outline), Text(context.watch<Store1>().post[i]['user'].toString())]),
                    Text(context.watch<Store1>().post[i]['content'].toString(), style: TextStyle(fontSize: 15)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            IconButton(onPressed: (){
                              // 하트 눌렀을 때 모든 게시글 하트 색이 변해서 수정해야 함
                              context.read<Store1>().addLike(i);
                            }, icon: Icon(Icons.favorite, color: context.watch<Store1>().likeColor),
                            ),
                            Text(context.watch<Store1>().post[i]['likes'].toString())
                          ],
                        ),
                        IconButton(onPressed: (){
                          // 눌렀을 때 댓글창으로 들어가지게 코드 넣었으면 좋겠음
                        }, icon: Icon(Icons.messenger_outline)),
                        IconButton(onPressed: (){ // 추후에 공유기능 추가
                        }, icon: Icon(Icons.ios_share)),
                        IconButton(onPressed: (){
                          // 저장 기능 같은 거 추가... 추후에
                        }, icon: Icon(Icons.bookmark_border))
                      ],)
                  ],
                )
            );
          }) ,
    );
  }
}

// 글 작성화면
class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        },),
        actions: [
          IconButton(onPressed: () async {
            // 여기 코드 추가해야 함! 누르면 갤러리에서 사진 선택하는 거로
            //사진 접근 권한 허용시 사용자 갤러리의 사진에 접근함.
                var ImageStatus = await Permission.photos.request();
                if(ImageStatus.isGranted) {
                  print('사진 접근 권한 허용');
                  var picker = ImagePicker();
                  var image = await picker.pickImage(
                      source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      context
                          .watch<Store1>()
                          .userImage = File(image.path);
                    });
                  }
                } else if (ImageStatus.isDenied || ImageStatus.isPermanentlyDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('사진 접근 권한이 필요합니다.')));
                }



          }, icon: Icon(Icons.photo_library_outlined)),
          IconButton(onPressed: (){
            context.read<Store1>().addPost();
            Navigator.pop(context);
          }, icon: Icon(Icons.send))],
      ),
      body: TextField(
        onChanged: (text){ context.read<Store1>().setUserContent(text); },
        decoration: InputDecoration(
          hintText: '자유롭게 글을 작성하세요...',
        ),
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }
}


// 마이페이지
class My extends StatelessWidget {
  const My({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('여기도 아직...ㅠ');
  }
}
