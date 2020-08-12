class VVariant{
  int size;
  String content_type,url;

  VVariant({this.size, this.content_type,this.url});

  factory VVariant.videofromJson(data){
    String url = data['url'];
    List<String> sizes = (url.substring(url.indexOf('vid/')+4,url.lastIndexOf('/'))).split('x');
    int size = 0;
    sizes.forEach((element) {
      size=size+int.parse(element);
      });
    return VVariant(
      size: size,
      content_type: data['content_type'],
      url: data['url']
    );
  }
}