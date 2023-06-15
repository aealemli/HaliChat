import 'package:HaliChat/pages/home_page.dart';
import 'package:HaliChat/service/database_service.dart';
import 'package:HaliChat/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfo extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminName;

  const GroupInfo({
    Key? key,
    required this.adminName,
    required this.groupName,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  Stream<List<String>>? membersStream;

  @override
  void initState() {
    super.initState();
    getMembers();
  }

  void getMembers() async {
    final DocumentSnapshot<Object?> membersSnapshot =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getGroupMembers(widget.groupId)
            .first;

    if (membersSnapshot.exists) {
      final dynamic data = membersSnapshot.data();
      if (data != null && data is Map) {
        final List<String> members = List<String>.from(data.keys);

        setState(() {
          membersStream = Stream.value(members);
        });
      }
    }
  }

  String getName(String r) {
    return r.substring(r.indexOf("_") + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Grup Bilgisi"),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Çıkış"),
                    content:
                        const Text("Gruptan çıkmak istediğine emin misin?"),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await DatabaseService(
                            uid: FirebaseAuth.instance.currentUser!.uid,
                          ).toggleGroupJoin(
                            widget.groupId,
                            getName(widget.adminName),
                            widget.groupName,
                          );
                          nextScreenReplace(context, const HomePage());
                        },
                        icon: const Icon(
                          Icons.done,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      widget.groupName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Grup: ${widget.groupName}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      Text("Yönetici: ${widget.adminName}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Üyeler",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: memberList()),
          ],
        ),
      ),
    );
  }

  Widget memberList() {
    return StreamBuilder<List<String>>(
      stream: membersStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final members = snapshot.data!;
          if (members.isNotEmpty) {
            return ListView.builder(
              itemCount: members.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final member = members[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        getName(member).substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(getName(member)),
                    subtitle: Text(getId(member)),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text("Üye yok"),
            );
          }
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(
                //color: Theme.of(context).primaryColor,
                ),
          );
        }
      },
    );
  }
}
