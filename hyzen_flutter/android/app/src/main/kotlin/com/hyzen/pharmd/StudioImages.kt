package com.hyzen.pharmd

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface

object StudioImages {
    fun load(path:String,maxDimension:Int=2000):Bitmap {
        val bounds=BitmapFactory.Options().apply{inJustDecodeBounds=true}
        BitmapFactory.decodeFile(path,bounds)
        require(bounds.outWidth>0 && bounds.outHeight>0){"Image unavailable"}
        bounds.inSampleSize=1
        while(maxOf(bounds.outWidth,bounds.outHeight)/bounds.inSampleSize>maxDimension) bounds.inSampleSize*=2
        bounds.inJustDecodeBounds=false
        val original=BitmapFactory.decodeFile(path,bounds) ?: error("Image unavailable")
        val orientation=try{ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION,ExifInterface.ORIENTATION_NORMAL)}catch(_:Exception){ExifInterface.ORIENTATION_NORMAL}
        val transform=Matrix()
        when(orientation){
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL->transform.setScale(-1f,1f)
            ExifInterface.ORIENTATION_ROTATE_180->transform.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL->transform.setScale(1f,-1f)
            ExifInterface.ORIENTATION_TRANSPOSE->{transform.setRotate(90f);transform.postScale(-1f,1f)}
            ExifInterface.ORIENTATION_ROTATE_90->transform.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE->{transform.setRotate(-90f);transform.postScale(-1f,1f)}
            ExifInterface.ORIENTATION_ROTATE_270->transform.setRotate(-90f)
            else->return original
        }
        try {val result=Bitmap.createBitmap(original,0,0,original.width,original.height,transform,true)
            if(result!==original)original.recycle();return result
        }catch(e:Exception){original.recycle();throw e}
    }
}
