package com.pingan.monkey;

import com.alibaba.fastjson.JSONObject;
import com.pingan.monkey.util.Shell;
import macaca.client.MacacaClient;

import java.io.IOException;
import java.text.NumberFormat;

/**
 * Created by test on 2017/4/6.
 */
public class MonkeyThread extends Thread {

    private static MacacaClient driver;
    private static int width, height, submitX_mim, submitX_max, submitY_mim, submitY_max, contentX_mim, contentX_max, contentY_mim, contentY_max, special_point_x, special_point_y;
    private static boolean needhelp = false;
    private static String UDID = "d9a4af288804d66c7e213874af50762baab5d649";
    private static String BUNDLEID = "com.okcoin.OKCoinAppstore";//"com.bafang.metal";
    private static String PORT = "3456";
    private static String PROXYPORT = "8100";
    private int backX = 25, backY = 40;
    private int eventcount = 0;


    public static void main(String[] args) throws Exception {
        executeParameter(args);

    }


    private static void executeParameter(String[] args) throws Exception{
        int optSetting = 0;

        for (; optSetting < args.length; optSetting++) {
            if ("-u".equals(args[optSetting])) {
                UDID = args[++optSetting];
            } else if ("-b".equals(args[optSetting])) {
                BUNDLEID = args[++optSetting];
            } else if ("-port".equals(args[optSetting])) {
                PORT = args[++optSetting];
            } else if ("-proxyport".equals(args[optSetting])) {
                PROXYPORT = args[++optSetting];
            } else if ("-h".equals(args[optSetting])) {
                needhelp = true;
                System.out.println(
                        "-u:设备的UDID\n" +
                                "-b:测试App的Bundle\n" +
                                "-port:macaca服务的端口，默认3456\n" +
                                "-proxyport:usb代理端口，默认8900");
                break;
            }

        }
        if (!needhelp) {
            try {
                System.out.println("测试设备:" + UDID + "\n" + "测试App:" + BUNDLEID);
                org.testng.Assert.assertTrue((!UDID.equals(null)) && (!BUNDLEID.equals(null)));
                setup();
                MonkeyThread m1 = new MonkeyThread();
                m1.setName("#####Thread 1111#######");
                m1.start();
                MonkeyThread m2 = new MonkeyThread();
                m2.setName("#####Thread 2222#######");
                m2.start();
            } catch (Exception e) {
                System.out.println("请确认参数配置,需要帮助请输入 java -jar iosMonkey.jar -h\n"
                        + "ERROR信息" + e.toString());
            }
        }
    }

    @Override
    public void run() {

        while (true) {
            //System.out.println(getName());
            switch (new MathRandom().PercentageRandom()) {
                case 0: {
                    try {
                        new MonkeyTapEvent(driver, width, height).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 1: {
                    try {
                        new MonkeySwipeEvent(driver, width, height).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 2: {
                    try {
                        new MonkeyBackEvent(driver, backX, backY).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 3: {
                    try {
                        new MonkeySubmitEvent(driver, submitX_mim, submitX_max, submitY_mim, submitY_max).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 4: {
                    try {
                        new MonkeyContentEvent(driver, contentX_mim, contentX_max, contentY_mim, contentY_max).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 5: {
                    try {
                        new MonkeyTapSpecialPointEvent(driver, special_point_x, special_point_y).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
                case 6: {
                    try {
                        new MonkeyHomeKeyEvent(driver, UDID, BUNDLEID).injectEvent();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    eventcount = eventcount + 1;
                    //System.out.println("---EVENT执行了：" + eventcount + "次---");
                    break;
                }
            }

        }
    }


    private static void init() throws IOException, InterruptedException {
        driver = new MacacaClient();
        JSONObject porps = new JSONObject();
        porps.put("platformName", "ios");
        porps.put("reuse", 3);
        porps.put("bundleId", BUNDLEID);
        porps.put("udid", UDID);
        porps.put("autoAcceptAlerts", true);
        porps.put("proxyPort", Integer.parseInt(PROXYPORT));
        JSONObject desiredCapabilities = new JSONObject();
        desiredCapabilities.put("desiredCapabilities", porps);
        desiredCapabilities.put("host", "127.0.0.1");
        desiredCapabilities.put("port", Integer.parseInt(PORT));
        try {
            driver.initDriver(desiredCapabilities);

        } catch (Exception e) {
            System.out.println("*******************************************\n\n\n" +
                    "请在命令行输入 macaca server --verbose 启动服务\n\n\n" +
                    "*******************************************\n");
        }
        //启动app守护进程
        Shell.launchAPP(UDID, BUNDLEID);
    }

    private static void setup() throws Exception{
        init();
        width = (Integer) driver.getWindowSize().get("width");
        height = (Integer) driver.getWindowSize().get("height");
        NumberFormat numberFormat = NumberFormat.getInstance();
        numberFormat.setMaximumFractionDigits(2);

        submitX_max = width - 1;
        submitX_mim = width / 10;
        submitY_max = height - 1;
        submitY_mim = height / 10 * 9;

        contentX_max = width - width / 10;
        contentX_mim = width / 10;
        contentY_max = height / 2 + height / 10;
        contentY_mim = height / 2 - height / 10;
        special_point_x = width / 2;
        special_point_y = (int) (height * 0.94);
    }
}
