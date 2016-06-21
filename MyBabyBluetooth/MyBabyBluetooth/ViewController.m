//
//  ViewController.m
//  MyBabyBluetooth
//
//  Created by yinzhihao on 16/6/12.
//  Copyright © 2016年 yzh. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"

#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGTH [[UIScreen mainScreen] bounds].size.height

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
{
    BabyBluetooth *baby;
    
    NSMutableArray *_peripherals;
    
    NSMutableArray *_peripheralsAD;
}

@property (nonatomic) UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *testView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [SVProgressHUD showInfoWithStatus:@"准备打开设备"];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGTH*2/3.0) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:_tableView];
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    _peripherals = [NSMutableArray array];
    _peripheralsAD = [NSMutableArray array];
    
    // 初始化BabyBluetooth 蓝牙库
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
    baby.scanForPeripherals().begin();
    
    //扫描设备 然后读取服务,然后读取characteristics名称和值和属性，获取characteristics对应的description的名称和值
    baby.scanForPeripherals().connectToPeripherals().discoverServices()
    .discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic()
    .readValueForDescriptors().begin();
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [baby cancelAllPeripheralsConnection];
    
    baby.scanForPeripherals().begin();
}

- (IBAction)sendMessage:(id)sender {
    NSLog(@"message:%@",self.testView.text);
}

#pragma mark -UIViewController 方法
//插入table数据
- (void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData
{
    if ([_peripherals containsObject:peripheral]) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [_peripherals insertObject:peripheral atIndex:0];
    [_peripheralsAD insertObject:advertisementData atIndex:0];
    
    [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)babyDelegate
{
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            [SVProgressHUD showInfoWithStatus:@"设备打开成功，开始扫描设备"];
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备：%@",peripheral.name);
        [weakSelf insertTableView:peripheral advertisementData:advertisementData];
    }];
    
    //设置设备连接成功的委托
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"连接上设备：%@",peripheral.name);
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"连接上设备：%@",peripheral.name]];
    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"%@断开连接",peripheral.name);
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%@断开连接",peripheral.name]];
    }];
    
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"-----Discover设备 %@ 的所有服务：%@",peripheral.name,peripheral.services);
        for (CBService *s in peripheral.services) {
            NSLog(@"服务之一：%@",s.UUID.UUIDString);
        }
        
        for (int i=0; i<_peripherals.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
            
            if ([cell.textLabel.text isEqualToString:peripheral.name]) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu个service",(unsigned long)peripheral.services.count];
            }
        }
    }];
    
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"-----Discover设备 %@ 的服务 %@ 的所有特征：%@",peripheral.name,service.UUID,service.characteristics);
        
        for (CBCharacteristic *c in service.characteristics) {
            NSLog(@"特征之一：%@",c.UUID.UUIDString);
        }
    }];
    
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"特征 %@ 的 值：%@",characteristic.UUID.UUIDString,characteristic.value);
    }];
    
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"-----Discover设备 %@ 的服务 %@ 的特征 %@ 的 所有Descriptors：%@",peripheral.name,characteristic.service.UUID,characteristic.UUID.UUIDString,characteristic.descriptors);
        
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"Descriptor之一：%@",d.UUID);
        }
    }];
    
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"descriptor %@ 的值：%@",descriptor.UUID,descriptor.value);
    }];
    
    //过滤器
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
        //        if ([peripheralName hasPrefix:@"Pxxxx"] ) {
        //            return YES;
        //        }
        //        return NO;
        
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length > 0) {
            return YES;
        }
        return NO;
    }];
}

- (void)connectPeripheral
{
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];

}

#pragma mark -table委托 table delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _peripherals.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"cell"];
    CBPeripheral *peripheral = [_peripherals objectAtIndex:indexPath.row];
    NSDictionary *ad = [_peripheralsAD objectAtIndex:indexPath.row];
    
    NSLog(@"-----advertisement:%@",ad);
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
    NSString *localName;
    if ([ad objectForKey:@"kCBAdvDataLocalName"]) {
        localName = [NSString stringWithFormat:@"%@",[ad objectForKey:@"kCBAdvDataLocalName"]];
    }else{
        localName = peripheral.name;
    }
    
    cell.textLabel.text = localName;
    //信号和服务
    cell.detailTextLabel.text = @"读取中...";
    //找到cell并修改detaisText
    NSArray *serviceUUIDs = [ad objectForKey:@"kCBAdvDataServiceUUIDs"];
    if (serviceUUIDs) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu个service",(unsigned long)serviceUUIDs.count];
    }else{
        cell.detailTextLabel.text = [NSString stringWithFormat:@"0个service"];
    }
    
    //次线程读取RSSI和服务数量
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //停止扫描
    [baby cancelScan];
    
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self connectPeripheral];
    
//    PeripheralViewContriller *vc = [[PeripheralViewContriller alloc]init];
//    vc.currPeripheral = [peripherals objectAtIndex:indexPath.row];
//    vc->baby = self->baby;
//    [self.navigationController pushViewController:vc animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
