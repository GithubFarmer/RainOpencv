//
//  ViewController.m
//  RainOpencv
//
//  Created by 喻永权 on 2018/2/28.
//  Copyright © 2018年 喻永权. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(50, 100, 200, 400)];
    _imageView.image =  [UIImage imageNamed:@"Image"];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.layer.borderColor = [UIColor redColor].CGColor;
    _imageView.layer.borderWidth = 2;
    [self.view addSubview:_imageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
    [_imageView addGestureRecognizer:tap];
    _imageView.userInteractionEnabled = YES;
}


//剪切图片，先给定一张图片，然后进行裁剪
- (UIImage *)image:(UIImage *)image forTargetSize:(CGSize)targetSize{
    
    UIImage *sourceImage = image;
    CGSize imageSize = sourceImage.size;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    
    NSInteger judge = 0;//声明一个判断属性
    if((imageHeight - imageWidth) > 0){
        
        CGFloat tempW =targetSize.width;
        CGFloat tempH = targetSize.height;
        targetSize.height = tempW;
        targetSize.width = tempH;
    }
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor;
    CGFloat scaleWidth = targetWidth;
    CGFloat scaleHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0, 0);
    
    //第一个判断，图片大小宽跟高都小于目标尺寸，直接返回image
    if(imageHeight < targetHeight && imageWidth < targetWidth){
        return image;
    }
    if(CGSizeEqualToSize(imageSize, targetSize) == NO){
        
        CGFloat widthFactor = targetWidth / imageWidth;
        CGFloat heightFactor = targetHeight / imageHeight;
        
        
        //分为四种情况
        // 第一种，widthFactor，heightFactor都小于1，也就是图片宽度跟高度都比目标图片大，要缩小
        
        if(widthFactor < 1 && heightFactor < 1){
            
            if(widthFactor > heightFactor){
                judge = 1;
                scaleFactor = heightFactor;
            }else{
                
                judge = 2;
                scaleFactor = widthFactor;
            }
        }else if(widthFactor > 1 && heightFactor < 1){
            
            judge = 3;
            scaleFactor = imageWidth / targetHeight;//计算高度缩小系数
        }else if(heightFactor > 1 && widthFactor < 1){
            
            judge = 4;
            scaleFactor = imageHeight / targetWidth;
        }else{
            
            //比目标图片小，需要做放大处理
        }
        
        scaleWidth = imageWidth * scaleFactor;
        scaleHeight = imageHeight * scaleFactor;
    }
    if(judge ==1){
        //右部分空白
        targetWidth = scaleWidth;//此时把原来目标剪切的宽度改小,例如原来可能是800,现在改成780
    }else if(judge ==2){
        //下部分空白
        targetHeight = scaleHeight;
    }else if(judge ==3){
        //第三种,高度不够比例,宽度缩小一点点
        targetWidth = scaleWidth;
    }else{
        //第三种,高度不够比例,宽度缩小一点点
        targetHeight = scaleHeight;
    }
    UIGraphicsBeginImageContext(targetSize);//开始剪切
    CGRect thumbnailRect =CGRectZero;//剪切起点(0,0)
    thumbnailRect.origin= thumbnailPoint;
    thumbnailRect.size.width= scaleWidth;
    thumbnailRect.size.height= scaleHeight;
    [sourceImage drawInRect:thumbnailRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();//截图拿到图片
    
    NSLog(@"==%@",newImage);
    return newImage;
}


- (void)tapAction{
    
    //转换图片
    cv::Mat changeImage = [self cvMatGrayFromImage:_imageView.image];
    //判断图片的模糊度
    burDetect(changeImage);
    
    UIImage *image1 =  [self image:_imageView.image forTargetSize:CGSizeMake(30, 60)];
    UIImageView  *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(260, 300, 40, 40)];
    imageView1.image = image1;
    [self.view addSubview:imageView1];
}

//将图片转化为 cv::Mat
- (cv::Mat)cvMatGrayFromImage:(UIImage *)image{
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows,cols,CV_8UC4);
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

//利用方差或者是标准差来甄别图片的模糊度
bool burDetect(cv::Mat srcImage)
{
    cv::Mat gray1;
    if (srcImage.channels() != 1){
        
        //进行灰度化
        cvtColor(srcImage, gray1, CV_RGB2GRAY);
    }else{
        
        gray1 = srcImage.clone();
    }
    cv::Mat tmp_m1, tmp_sd1; //用来存储均值和方差
    double m1 = 0,sd1 = 0;
    //使用3x3的Laplacian算子卷积滤波
    Laplacian(gray1,gray1,CV_16S,3);
    //归到0～255
    convertScaleAbs(gray1, gray1);
    //计算均值和方差
    meanStdDev(gray1,tmp_m1,tmp_sd1);
    m1 = tmp_m1.at<double>(0,0);//均值
    sd1 = tmp_sd1.at<double>(0,0);//标准差，方差的开平方
    //cout <<"原图像：" << end1;
    std::cout <<"均值：" << m1 << ", 方差：" << sd1*sd1 << ", 标准差：" << sd1 <<std::endl;
    if (sd1 < 20)
    {
        std::cout << "原图像是模糊图像" << std::endl;
        return 0;
    }
    else
    {
        std::cout << "原图像是清晰图像" << std::endl;
        return 1;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
