import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/common.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_pdf_engine.dart';

class _Block {
  _Block(this.type,{String text='',this.path=''}) : text=TextEditingController(text:text);
  final String type;
  final TextEditingController text;
  final String path;
  bool bold=false,italic=false,underline=false;
  String align='left';
  Map<String,Object> toMap()=>{'type':type,'text':text.text,'path':path,'bold':bold,'italic':italic,'underline':underline,'align':align};
}

class RichDocumentScreen extends ConsumerStatefulWidget {
  const RichDocumentScreen({super.key, this.template});
  final String? template;
  @override
  ConsumerState<RichDocumentScreen> createState()=>_RichDocumentScreenState();
}
class _RichDocumentScreenState extends ConsumerState<RichDocumentScreen> {
  final _title=TextEditingController(text:'My document');
  final _blocks=<_Block>[_Block('heading'),_Block('paragraph')];
  bool _busy=false;
  @override
  void initState() {
    super.initState();
    final template = widget.template;
    if (template != null) {
      for (final block in _blocks) { block.text.dispose(); }
      _title.text = template;
      _blocks..clear()..addAll(template == 'Revision checklist'
        ? [_Block('heading', text: 'Revision checklist'), _Block('list', text: 'Review key concepts\nPractise questions\nRevisit difficult topics')]
        : [_Block('heading', text: 'Study notes'), _Block('heading', text: 'Learning objectives'), _Block('list'), _Block('heading', text: 'Key concepts'), _Block('paragraph'), _Block('heading', text: 'Revision questions'), _Block('list')]);
    }
  }
  @override
  void dispose(){_title.dispose();for(final b in _blocks){b.text.dispose();}super.dispose();}
  Future<void> _image() async {
    try {
      final files=await StudioPdfEngine.pickFiles();
      final images=files.where((f)=>RegExp(r'\.(png|jpe?g|webp)$',caseSensitive:false).hasMatch(f.name));
      if(!mounted)return;
      setState(()=>_blocks.addAll(images.take(10).map((f)=>_Block('image',path:f.path,text:f.name))));
    }catch(_){if(mounted)showHSnack(context,'Could not select an image.',error:true);}
  }
  Future<void> _save(String format) async {
    if(_busy)return;
    if(!_blocks.any((b)=>b.type=='image'||b.text.text.trim().isNotEmpty)){showHSnack(context,'Write something first.',error:true);return;}
    setState(()=>_busy=true);
    try {
      final path=await StudioPdfEngine.richDocument(_blocks.map((b)=>b.toMap()).toList(),format);
      final name=_title.text.trim().isEmpty?'Document':_title.text.trim();
      final file=await ref.read(pdfStudioHistoryProvider.notifier).importFile(path,originalFileName:'$name.$format',sourceType:'CREATED',operationBadge:'CREATED');
      if(!mounted)return;
      final router=GoRouter.of(context);Navigator.pop(context);router.push('/pdf-studio/viewer/${file.id}');
    }catch(_){if(mounted)showHSnack(context,'Could not save your document. Try again.',error:true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Document writer')),
    body:ReorderableListView(
      padding:const EdgeInsets.all(20),
      header:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        TextField(controller:_title,maxLength:100,decoration:const InputDecoration(labelText:'Document name')),
        Wrap(spacing:6,runSpacing:6,children:[
          for(final option in [('paragraph','Paragraph'),('heading','Heading'),('list','List'),('table','Table')])
            ActionChip(label:Text(option.$2),onPressed:_busy||_blocks.length>=100?null:()=>setState(()=>_blocks.add(_Block(option.$1)))),
          ActionChip(label:const Text('Image'),avatar:const Icon(Icons.image_outlined),onPressed:_busy?null:_image),
        ]),const SizedBox(height:16),if(_busy)const LinearProgressIndicator(),
      ]),
      footer:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Wrap(spacing:10,runSpacing:8,children:[
        FilledButton.icon(onPressed:_busy?null:()=>_save('pdf'),icon:const Icon(Icons.picture_as_pdf),label:const Text('Save PDF')),
        OutlinedButton.icon(onPressed:_busy?null:()=>_save('docx'),icon:const Icon(Icons.description_outlined),label:const Text('Save Word document')),
      ])),
      onReorder:(from,to)=>setState((){final moved=_blocks.removeAt(from);_blocks.insert(to>from?to-1:to,moved);}),
      children:[for(final block in _blocks) Card(key:ObjectKey(block),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(children:[Expanded(child:Text(block.type=='image'?'Image':block.type[0].toUpperCase()+block.type.substring(1))),
          IconButton(tooltip:'Remove block',onPressed:_busy?null:()=>setState((){_blocks.remove(block);block.text.dispose();}),icon:const Icon(Icons.close_rounded)),const Icon(Icons.drag_handle)]),
        if(block.type!='image')...[
          Wrap(spacing:4,children:[
            IconButton(tooltip:'Bold',isSelected:block.bold,onPressed:()=>setState(()=>block.bold=!block.bold),icon:const Icon(Icons.format_bold)),
            IconButton(tooltip:'Italic',isSelected:block.italic,onPressed:()=>setState(()=>block.italic=!block.italic),icon:const Icon(Icons.format_italic)),
            IconButton(tooltip:'Underline',isSelected:block.underline,onPressed:()=>setState(()=>block.underline=!block.underline),icon:const Icon(Icons.format_underline)),
            for(final align in [('left',Icons.format_align_left),('center',Icons.format_align_center),('right',Icons.format_align_right)])
              IconButton(tooltip:'Align ${align.$1}',isSelected:block.align==align.$1,onPressed:()=>setState(()=>block.align=align.$1),icon:Icon(align.$2)),
          ]),
          TextField(controller:block.text,minLines:block.type=='heading'?1:3,maxLines:12,maxLength:20000,
            textAlign:block.align=='center'?TextAlign.center:block.align=='right'?TextAlign.right:TextAlign.left,
            style:TextStyle(fontWeight:block.bold||block.type=='heading'?FontWeight.bold:FontWeight.normal,fontStyle:block.italic?FontStyle.italic:FontStyle.normal,decoration:block.underline?TextDecoration.underline:TextDecoration.none),
            decoration:InputDecoration(hintText:block.type=='table'?'Medicine | Dose\nExample | 5 mg':'Write here…',helperText:block.type=='table'?'One row per line. Separate cells with |.':null)),
        ]else ListTile(leading:const Icon(Icons.image_outlined),title:Text(block.text.text,maxLines:1,overflow:TextOverflow.ellipsis)),
      ])))],
    ),
  );
}
