import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/post_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({required this.post, super.key});
  final PostModel post;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          elevation: 0,
          title: Text(
            'Post',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.iconPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: PostCard(post: post),
        ),
      );
}
