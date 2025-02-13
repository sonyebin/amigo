import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // provider 사용
import 'package:permission_handler/permission_handler.dart';

//기본 firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // fire store 쓰기 위해
//import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage -> 유료라는데...

import 'package:intl/intl.dart'; // 게시글 날짜 포맷팅 위함

final firestore = FirebaseFirestore.instance;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
      ChangeNotifierProvider(
        create: (c) => Store1(),
        child: const MyApp(),
      )
  );
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
  var content ='';
  var userImage;

  changePage(i) {
    tab = i;
    notifyListeners(); // state 사용 중인 위젯 자동 재렌더링
  }

  /*uploadImage(File imageFile) async {
    try {
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // 업로드 완료 후 이미지 다운로드 URL 가져오기
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      return ''; // 실패 시 빈 문자열 반환
    }
  }*/

  addPost(BuildContext context) async {
    // 내용이 없을 때 게시물 추가하지 않음... 임시로 snackbar 해놨으나 나중에 변경했으면 좋겠음... 다이얼로그가 더 나을 거 같은데 안 떠서ㅜㅜ
    if ((content == null || content.isEmpty) && userImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내용을 입력하세요.')));
    } else {
      // firestore에 게시글 데이터 저장
      DocumentReference docRef = await firestore.collection('posts').add({
        'id': post.length + 1,
        //'image': userImage, -> fire storage 하게 되면 수정
        'likes': 0,
        'content': content,
        'liked': false,
        'user': 'yes_empty',
        'date': FieldValue.serverTimestamp(), // 작성 시간 자동 추가
      });

      // 날짜 출력 형식 포맷팅
      String formattedDate = "";
      DocumentSnapshot doc = await docRef.get(); // Firestore에서 데이터 가져오기
      if (doc.exists && doc['date'] != null) {
        DateTime dateTime = (doc['date'] as Timestamp).toDate();
        formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      }

      // 고유 id 임시 지정
      var myData = {'id': docRef.id, 'image':userImage, 'likes':0, 'date': formattedDate,
        'content': content, 'liked': false, 'user':'yes_empty'};
      post.insert(0, myData);
      notifyListeners();

      // 글 업로드 후 사진 및 내용 초기화
      userImage = null;
      content = '';
    }
  }

  setUserContent(text){
    content = text;
  }

  addLike(i) async{
    var postId = post[i]['id'];
    var isLiked = post[i]['liked'];
    var likes = post[i]['likes'];

    post[i]['liked'] = !isLiked;
    post[i]['likes'] = isLiked ? likes - 1 : likes + 1;
    notifyListeners();

    // 5초 후에 Firestore에 업데이트 (최적화)
    Future.delayed(Duration(seconds: 5), () {
      FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'liked': post[i]['liked'],
        'likes': post[i]['likes'],
      });
    });
  }
}

// 홈 위젯
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("아직")
      ),
    );
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
                    if(context.watch<Store1>().post[i]['image'] != null)
                      Image.file(context.watch<Store1>().post[i]['image']),
                    if(context.watch<Store1>().post[i]['content'].isNotEmpty)
                      Text(context.watch<Store1>().post[i]['content'].toString(), style: TextStyle(fontSize: 15)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            IconButton(onPressed: (){
                              // 하트 눌렀을 때 모든 게시글 하트 색이 변해서 수정해야 함 -> 수정 완
                              context.read<Store1>().addLike(i);
                            }, icon: Icon(Icons.favorite, color: context.watch<Store1>().post[i]['liked'] ? Colors.red : Colors.grey),
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
class Upload extends StatefulWidget with WidgetsBindingObserver{
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        },),
        actions: [
          IconButton(onPressed: () async {
            //사진 접근 권한 허용시 사용자 갤러리의 사진에 접근함.
            var ImageStatus = await Permission.photos.status;
            if(ImageStatus.isGranted) {
              // 권한 없는데도 이 로직이 실행됨... 왜지?
              print('사진 접근 권한 허용');
              var picker = ImagePicker();
              var image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                context.read<Store1>().userImage = File(image.path);
              }
              context.read<Store1>().notifyListeners();
            } else if(ImageStatus.isDenied){
              print('권한이 일시적으로 거부됨');
              await Permission.photos.request();  // 권한 요청
            } else { // ImageStatus.isPermanentlyDenied일 때
              print('권한 영구거부');
              showDialog(context: context, builder: (context){
                return AlertDialog(
                  content: Text("사진 접근 권한이 없습니다. 설정으로 이동하시겠습니까?"),
                  actions: [
                    Row(
                      children: [
                        TextButton(onPressed: (){ openAppSettings(); }, child: Text('예')),
                        TextButton(onPressed: (){ Navigator.pop(context); }, child: Text('아니오'))])],
                );
              });
            }
          }, icon: Icon(Icons.photo_library_outlined)),
          IconButton(onPressed: (){
            context.read<Store1>().addPost(context);
            Navigator.pop(context);
          }, icon: Icon(Icons.send))],
      ),
      body: Column(
        // 사진 추가되면 글 쓸 때 overflow... 사진 크기 조절이나 뭐 해야 함
        children: [
          if(context.watch<Store1>().userImage != null)
            Image.file(context.watch<Store1>().userImage),
          TextField(
          onChanged: (text){ context.read<Store1>().setUserContent(text); },
          decoration: InputDecoration(
            hintText: '자유롭게 글을 작성하세요...',
          ),
          keyboardType: TextInputType.multiline,
          maxLines: null,
        ),]
      ),
    );
  }
}


// 마이페이지
class My extends StatelessWidget {
  const My({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("아직")
      ),
    );
  }
}

