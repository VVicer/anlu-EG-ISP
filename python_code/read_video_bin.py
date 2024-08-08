import cv2
import numpy as np
import matplotlib.pyplot as plt


def gamma(image, gamma):
    normalized_image = image.astype(np.uint16) / 65535.0
    # 应用Gamma变换到每个通道
    corrected_image = np.power(normalized_image, gamma)
    # 将浮点数像素值映射回16位整数范围(0, 65535)
    corrected_image = (corrected_image * 255).astype(np.uint8)
    return corrected_image


def awb_gbrg(img):
    # 分割 GBRG 格式图像的 R、G、B 通道
    gbrg_r = img[1::2, ::2]  # 红色通道
    gbrg_g1 = img[::2, ::2]  # 绿色通道 1
    gbrg_g2 = img[1::2, 1::2]  # 绿色通道 2
    gbrg_b = img[::2, 1::2]  # 蓝色通道

    # 计算 R 和 B 通道的平均值
    mean_r = np.mean(gbrg_r)
    mean_b = np.mean(gbrg_b)
    mean_g = np.mean(gbrg_g1 + gbrg_g2)
    # print(mean_g/mean_r)
    # print(mean_g/mean_b)
    # print(gbrg_r.dtype)
    # 对 R 和 B 通道应用增益
    gbrg_r_corrected = (np.clip(gbrg_r * 1.9, 0, 255)).astype(np.uint8)
    # print(np.max(gbrg_r_corrected))
    # print(gbrg_r_corrected.dtype)
    gbrg_b_corrected = (np.clip(gbrg_b * 1.75, 0, 255)).astype(np.uint8)
    gbrg_g1_corrected = gbrg_g1
    gbrg_g2_corrected = gbrg_g2

    # 合并修正后的 R、G、B 通道
    img_corrected = np.zeros_like(img)
    img_corrected[1::2, ::2] = gbrg_r_corrected
    img_corrected[::2, ::2] = gbrg_g1_corrected
    img_corrected[1::2, 1::2] = gbrg_g2_corrected
    img_corrected[::2, 1::2] = gbrg_b_corrected

    # img_corrected[:,:,0]= gbrg_r_corrected  # 红色通道
    # img_corrected[:,:,1]= gbrg_g  # 绿色通道 1
    # img_corrected[:,:,2]= gbrg_b_corrected  # 蓝色通道

    return img_corrected


def de_awb(img):
    # 分割 GBRG 格式图像的 R、G、B 通道
    gbrg_r = img[:, :, 0]  # 红色通道
    gbrg_g = img[:, :, 1]  # 绿色通道
    gbrg_b = img[:, :, 2]  # 蓝色通道

    # 计算 R 和 B 通道的平均值
    mean_r = np.mean(gbrg_r)
    mean_b = np.mean(gbrg_b)
    mean_g = np.mean(gbrg_g)

    K = (mean_r + mean_b + mean_g) / 3

    K_r = K / mean_r
    K_g = K / mean_g
    K_b = K / mean_b

    # 对 R 和 B 通道应用增益
    gbrg_r_corrected = np.clip(gbrg_r * K_r, 0, 65520)
    gbrg_b_corrected = np.clip(gbrg_r * K_b, 0, 65520)
    gbrg_g_corrected = np.clip(gbrg_r * K_g, 0, 65520)

    # 合并修正后的 R、G、B 通道
    img_corrected = np.zeros_like(img)
    img_corrected[:, :, 0] = gbrg_r_corrected
    img_corrected[:, :, 1] = gbrg_g_corrected
    img_corrected[:, :, 2] = gbrg_b_corrected

    return img_corrected


def cut(img):
    normalized_image = img>>8
    return normalized_image.astype(np.uint8)


def BlC(img):
    np.set_printoptions(threshold=np.inf)
    img[img > 4] -= 4
    img[img < 4] = 0
    return img


def demosaic(img, heigt, width):
    rgb_frame = np.zeros((heigt, width, 3), dtype=np.uint8)
    # 奇行奇列像素点,索引值从0开始算奇数和偶数
    # print(img[i,j])
    rgb_frame[1:-2:2, 3:-2:2, 0] = img[1:-2:2,2:-2:2]/2 + img[1:-2:2,4:-1:2]/2
    # rgb_frame[1:-2:2, 3:-2:2, 1] = img[0:-2:2,2:-2:2]/4 + img[0:-2:2,4:-1:2]/4 + img[2:-1:2,2:-2:2]/4 + img[2:-1:2,4:-1:2]/4
    rgb_frame[1:-2:2, 3:-2:2, 1] = img[1:-2:2, 3:-2:2]
    rgb_frame[1:-2:2, 3:-2:2, 2] = img[0:-2:2,3:-2:2]/2 + img[2:-1:2,3:-2:2]/2
    # 奇行偶列像素点
    rgb_frame[1:-2:2, 4:-1:2, 0] = img[1:-2:2, 4:-1:2]
    rgb_frame[1:-2:2, 4:-1:2, 1] = img[1:-2:2, 3:-2:2] / 4 + img[1:-2:2,5::2] / 4 + img[0:-2:2, 4:-1:2] / 4 + img[2:-1:2, 2:-2:2] / 4
    rgb_frame[1:-2:2, 4:-1:2, 2] = img[0:-2:2,3:-2:2]/4  + img[0:-2:2,5::2]/4 + img[2:-1:2,3:-2:2]/4 + img[2:-1:2,5::2]/4
    # 偶行奇列像素点
    rgb_frame[2:-1:2, 3:-2:2, 0] = img[1:-2:2,2:-2:2]/4 + img[1:-2:2,4:-1:2]/4 + img[3::2, 2:-2:2]/4 + img[3::2,4:-1:2] / 4
    rgb_frame[2:-1:2, 3:-2:2, 1] = img[1:-2:2, 3:-2:2]/4 + img[2:-1:2,2:-2:2]/4 + img[2:-1:2,4:-1:2]/4 + img[3::2,3:-2:2] / 4
    rgb_frame[2:-1:2, 3:-2:2, 2] = img[2:-1:2, 3:-2:2]
    # 偶行偶列像素点
    rgb_frame[2:-1:2, 4:-1:2, 0] = img[1:-2:2,4:-1:2]/2 + img[3::2,4:-1:2]/2
    # rgb_frame[2:-1:2, 4:-1:2, 1] = img[1:-2:2, 3:-2:2]/4 + img[1:-2:2,5::2]/4+img[3::2,3:-2:2]/4+img[3::2,5::2]/4
    rgb_frame[2:-1:2, 4:-1:2, 1] = img[2:-1:2, 4:-1:2]
    rgb_frame[2:-1:2, 4:-1:2, 2] = img[2:-1:2, 3:-2:2]/2 + img[0:-2:2,5::2]/2

    return rgb_frame



def read_binary_gbrg_video(file_path, width, height):
    # 打开二进制视频文件
    with open(file_path, 'rb') as file:
        # 读取整个文件内容
        data = file.read()

    # 将二进制数据解析为图像数据
    # 这里假设每个像素占用一个字节
    img_data = np.frombuffer(data, dtype=np.uint16)
    img_data = img_data.reshape((-1, height, width))
    np.set_printoptions(threshold=np.inf)  # np.inf表示正无穷
    # hex_array_0 = [hex(x) for x in img_data[0:1024]]
    # print(hex_array_0)

    img_data_swapped = ((img_data & 0xFF) << 8) | ((img_data >> 8) & 0xFF)

    # hex_array_1 = [hex(x) for x in img_data_swapped[0:1024]]
    # print(hex_array_1)

    # print(img_data_swapped.ndim)

    img_data_swapped = img_data_swapped.reshape((-1, height, width))
    # np.set_printoptions(threshold=np.inf)  # np.inf表示正无穷
    #
    # hex_array_2 = [hex(x) for x in img_data_swapped[0][0]]
    # # hex_array_2 = [hex(x) for x in img_data_swapped[0][2]]
    # print(hex_array_2)
    # # print(hex_array_2)

    # 创建视频显示窗口
    cv2.namedWindow('Video', cv2.WINDOW_NORMAL)
    cv2.resizeWindow('Video', width, height)
    maxest = 100
    # 显示视频
    for frame in img_data_swapped:
        # if(maxest==100):
        # 将 GBRG 格式图像转换为 BGR 格式q
        #     maxest += 1
        # # de_awb(frame)
        cut_frame = cut(frame)
        blc_frame = BlC(cut_frame)
        awb_frame = awb_gbrg(blc_frame)
        # bgr_frame = demosaic(blc_frame, height, width)
        #     # print(bgr_frame.ndim)
        bgr_frame = cv2.cvtColor(awb_frame, cv2.COLOR_BayerGRBG2BGR)
        # rgb_frame = np.zeros((height, width, 3), dtype=np.uint16)
        # rgb_frame[::1,::1,2] = frame
        # bgr_frame = gamma(bgr_frame,0.8)
        # print(np.max(bgr_frame))
        # bgr_frame = de_awb(bgr_frame)
        # if count==0:
        # cv2.imshow('Video', bgr_frame)bgr_frame
        # awb_frame = awb_gbrg(bgr_frame)
        rgb_frame = cv2.cvtColor(bgr_frame, cv2.COLOR_RGB2BGR)
        cv2.imshow('Video', rgb_frame)
        # plt.imshow(bgr_frame)
        # 等待一段时间，按 'q' 键退出
        if cv2.waitKey(25) & 0xFF == ord('q'):
            break

    # 关闭视频显示窗口
    print(maxest)
    cv2.destroyAllWindows()


# 示例用法
file_path = 'day.bin'  # 替换为你的二进制视频文件路径
width = 1936  # 视频宽度
height = 1088  # 视频高度
read_binary_gbrg_video(file_path, width, height)
