import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/studio_pdf_engine.dart';

class StudioPageThumbnail extends StatefulWidget {
  const StudioPageThumbnail({super.key,required this.page});
  final StudioPage page;
  @override
  State<StudioPageThumbnail> createState()=>_StudioPageThumbnailState();
}
class _StudioPageThumbnailState extends State<StudioPageThumbnail> {
  late Future<({Uint8List bytes,int width,int height})> _image;
  @override
  void initState(){super.initState();_image=StudioPdfEngine.renderPage(widget.page.path,widget.page.index);}
  @override
  void didUpdateWidget(covariant StudioPageThumbnail old){super.didUpdateWidget(old);if(old.page.path!=widget.page.path || old.page.index!=widget.page.index)_image=StudioPdfEngine.renderPage(widget.page.path,widget.page.index);}
  @override
  Widget build(BuildContext context)=>FutureBuilder(future:_image,builder:(_,snapshot){
    final data=snapshot.data;
    return data==null ? const Center(child:Icon(Icons.description_outlined)) : RotatedBox(quarterTurns:widget.page.rotation~/90,child:Image.memory(data.bytes,cacheWidth:200,fit:BoxFit.contain));
  });
}
