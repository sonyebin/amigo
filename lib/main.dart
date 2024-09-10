import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // provider 사용


//githubtest
void main() {
  runApp(const MyApp());

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
}
