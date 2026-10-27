import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../content/data/content_providers.dart';

/// Real catalog promotions; no invented prices or duplicated character art.
class ProfilePromotions extends ConsumerStatefulWidget {
  const ProfilePromotions({super.key});
  @override
  ConsumerState<ProfilePromotions> createState() => _ProfilePromotionsState();
}
class _ProfilePromotionsState extends ConsumerState<ProfilePromotions> {
  int _page=0;
  @override
  Widget build(BuildContext context) {
    final settings=ref.watch(siteSettingsProvider);
    if(!settings.sectionEnabled('shop')) return const SizedBox.shrink();
    final products=ref.watch(productsProvider).valueOrNull?.data.where((p)=>!p.hidden).take(5).toList();
    final slides= <(String,String,IconData,String,String?)>[
      if(products != null) for(final p in products)
        (p.name,'${settings.currency} ${p.price}',Icons.shopping_bag_outlined,'/shop/p/${p.id}',p.image),
      if(products == null || products.isEmpty)
        ('Pharm-D essentials',settings.shopComingSoon ? 'Discover what is coming' : 'Tools for your study journey',Icons.shopping_bag_outlined,'/shop',null),
      ('Your offline library','Keep your notes within reach',Icons.download_done_rounded,'/downloads',null),
    ];
    final theme=Theme.of(context);
    return Column(children:[
      SizedBox(height: 152 * MediaQuery.textScalerOf(context).scale(1).clamp(1,1.8),
        child: PageView.builder(itemCount:slides.length,onPageChanged:(i)=>setState(()=>_page=i),
          itemBuilder:(_,i){ final s=slides[i]; return Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:Card(
            clipBehavior:Clip.antiAlias, color:theme.colorScheme.primaryContainer,
            child:InkWell(onTap:()=>context.push(s.$4),child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
              if(s.$5 != null) ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(s.$5!,width:72,height:96,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Icon(s.$3,size:42)))
              else Icon(s.$3,size:42,color:theme.colorScheme.primary),
              const SizedBox(width:16),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(s.$1,maxLines:2,overflow:TextOverflow.ellipsis,style:theme.textTheme.titleMedium),
                const SizedBox(height:6),Text(s.$2,maxLines:2,overflow:TextOverflow.ellipsis,style:theme.textTheme.bodySmall),
              ])),const Icon(Icons.chevron_right_rounded),
            ]))),
          ));}),
      ),
      const SizedBox(height:8),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(var i=0;i<slides.length;i++)
        Container(margin:const EdgeInsets.symmetric(horizontal:3),width:i==_page?18:6,height:6,decoration:BoxDecoration(color:i==_page?theme.colorScheme.primary:theme.colorScheme.outlineVariant,borderRadius:BorderRadius.circular(8))),
      ]),
    ]);
  }
}
