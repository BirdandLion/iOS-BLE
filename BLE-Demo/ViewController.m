//
//  ViewController.m
//  蓝牙BLE-Demo
//
//  Created by Gandalf on 16/12/5.
//  Copyright © 2016年 Gandalf. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <MBProgressHUD/MBProgressHUD.h>

#define BAND_NAME       @"MI Band 2"

#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

// 蓝牙central
@property (nonatomic, strong) CBCentralManager *mgr;

// 蓝牙扫描到的所有外设
@property (nonatomic, strong) NSMutableArray *peripherals;

// tableView数据
@property (nonatomic, strong) NSMutableDictionary *dataSource;

// 蓝牙外设的服务的UUID数组
@property (nonatomic, strong) NSMutableArray *services;

// 用来展示服务和特征的tableView
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    UIButton *startScan = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:startScan];
    startScan.frame = CGRectMake(30, 50, 80, 50);
    startScan.backgroundColor = [UIColor orangeColor];
    [startScan setTitle:@"重新扫描" forState:UIControlStateNormal];
    [startScan addTarget:self action:@selector(startScanClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *stopScan = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:stopScan];
    stopScan.frame = CGRectMake(140, 50, 80, 50);
    stopScan.backgroundColor = [UIColor orangeColor];
    [stopScan setTitle:@"停止扫描" forState:UIControlStateNormal];
    [stopScan addTarget:self action:@selector(stopScanClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *connectPeripheral = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:connectPeripheral];
    connectPeripheral.frame = CGRectMake(250, 50, 80, 50);
    connectPeripheral.backgroundColor = [UIColor orangeColor];
    [connectPeripheral setTitle:@"连接外设" forState:UIControlStateNormal];
    [connectPeripheral addTarget:self action:@selector(connectPeripheralClick) forControlEvents:UIControlEventTouchUpInside];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, self.view.bounds.size.height - 120)];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableHeaderView = [self createHeaderView];
    
    // 创建蓝牙中心管理器
    dispatch_queue_t queue = dispatch_queue_create("bluetooth", DISPATCH_QUEUE_SERIAL);
    CBCentralManager *mgr = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    self.mgr = mgr;
}

- (void)startScanClick
{
    NSLog(@"%s", __FUNCTION__);
    self.peripherals = nil;
    self.dataSource = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    });
    
    [self.mgr scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScanClick
{
    NSLog(@"%s", __FUNCTION__);
    [self.mgr stopScan];
}

- (void)connectPeripheralClick
{
    NSLog(@"%s", __FUNCTION__);
    self.dataSource = nil;
    for (CBPeripheral *peripheral in self.peripherals) {
        [self.mgr connectPeripheral:peripheral options:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *deviceNameLb = (UILabel*)[self.tableView tableHeaderView];
        deviceNameLb.text = nil;
    });
}

- (UILabel *)createHeaderView
{
    UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 60)];
    headerView.font = [UIFont systemFontOfSize:40];
    headerView.textColor = [UIColor blueColor];
    headerView.textAlignment = NSTextAlignmentCenter;
    headerView.backgroundColor = [UIColor lightGrayColor];
    
    return headerView;
}


#pragma mark - dataSource delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.services == nil || self.services.count == 0) {
        return 0;
    } else {
        return self.services.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *srvUUID = self.services[section];
    NSMutableArray *chrs = [self.dataSource objectForKey:srvUUID];
    return chrs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    
    NSString *srvUUID = self.services[indexPath.section];
    NSMutableArray *chrs = [self.dataSource objectForKey:srvUUID];
    CBCharacteristic *chr = chrs[indexPath.row];
    
    NSString *chrUUID = [NSString stringWithFormat:@"特征UUID: %@ ---> 特征描述UUID，", chr.UUID.UUIDString];
    NSString *chrValue = [[NSString alloc] initWithData:chr.value encoding:NSUTF8StringEncoding];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"特征值：%@", chrValue];
    cell.detailTextLabel.textColor = [UIColor redColor];
    
    NSString *desc = chr.description;
    NSArray *tmpArray = [desc componentsSeparatedByString:@","];
    for (NSString *str in tmpArray) {
        if ([str containsString:@"UUID"]) {
            NSArray *innerArray = [str componentsSeparatedByString:@"="];
            NSString *descUUID = innerArray.lastObject;
            
            cell.textLabel.text = [chrUUID stringByAppendingString:descUUID];
            cell.textLabel.numberOfLines = 0;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 130;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CBService *service = [self.services objectAtIndex:section];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
    title.font = [UIFont systemFontOfSize:20];
    title.text = [NSString stringWithFormat:@"服务UUID：%@", service];
    title.textColor = [UIColor blueColor];
    title.textAlignment = NSTextAlignmentLeft;
    title.backgroundColor = [UIColor yellowColor];
    
    return title;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStatePoweredOn:
        {
            NSLog(@"开启蓝牙, 开始扫描");
            
            [self startScanClick];
        }
            break;
        case CBManagerStateUnsupported:
            NSLog(@"不支持蓝牙");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"蓝牙未打开");
            break;
            
        default:
            NSLog(@"蓝牙打开失败");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:BAND_NAME]) {
        
        NSLog(@"发现蓝牙新设备：%@", peripheral.name);
        peripheral.delegate = self;
        [self.peripherals addObject:peripheral];
        
        [self.mgr stopScan];
        
        [self connectPeripheralClick];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"已经断开蓝牙设备：%@", peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if ([peripheral.name isEqualToString:BAND_NAME]) {
        NSLog(@"已经连接到：%@, 搜索服务中...", peripheral.name);

        dispatch_async(dispatch_get_main_queue(), ^{
            UILabel *deviceNameLb = (UILabel*)[self.tableView tableHeaderView];
            deviceNameLb.text = BAND_NAME;
            
            [MBProgressHUD hideHUDForView:self.view animated:NO];
        });
        
        [peripheral discoverServices:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"无法连接到：%@", peripheral.name);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *deviceNameLb = (UILabel*)[self.tableView tableHeaderView];
        deviceNameLb.text = nil;
    });
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        
        if (self.services == nil || self.services.count == 0) {
            NSLog(@"1 发现%@的服务：%@", peripheral.name, service.UUID.UUIDString);
            
            // 添加到服务数组
            [self.services addObject:service.UUID.UUIDString];
            // 添加到tableView的数据数组
            NSMutableArray *characteristics = [NSMutableArray arrayWithCapacity:0];
            [self.dataSource setObject:characteristics forKey:service.UUID.UUIDString];
            
            [peripheral discoverCharacteristics:nil forService:service];
        } else {

            BOOL exist = NO;
            for (NSString *srvUUID in self.services) {
                if ([srvUUID isEqualToString:service.UUID.UUIDString]) {
                    exist = YES;
                    break;
                }
            }
            if (!exist) {
                NSLog(@"2 发现%@的服务：%@", peripheral.name, service.UUID.UUIDString);
                
                // 添加到服务数组
                [self.services addObject:service.UUID.UUIDString];
                // 添加到tableView的数据数组
                NSMutableArray *characteristics = [NSMutableArray arrayWithCapacity:0];
                [self.dataSource setObject:characteristics forKey:service.UUID.UUIDString];
                
                [peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        for (NSString *serviceUUID in self.services) {
            if ([serviceUUID isEqualToString:service.UUID.UUIDString]) {
                NSMutableArray *chrs = [self.dataSource objectForKey:serviceUUID];
                if (chrs == nil) {
                    chrs = [NSMutableArray arrayWithCapacity:0];
                }
                
                if (chrs == nil || chrs.count == 0) {
                    [chrs addObject:characteristic];
     
                    // 监听外设特征值
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    // 读取特征数据
                    [peripheral readValueForCharacteristic:characteristic];
                } else {
                    BOOL exist = NO;
                    for (CBCharacteristic *chr in chrs) {
                        if ([chr.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString]) {
                            exist = YES;
                            break;
                        }
                    }
                    
                    if (!exist) {
                        [chrs addObject:characteristic];
                        
                        // 监听外设特征值
                        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                        // 读取特征数据
                        [peripheral readValueForCharacteristic:characteristic];
                    }
                }
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"发现%@ - 特征：UUID: %@, desc: %@, props: %zd, value: %@", peripheral.name, characteristic.UUID.UUIDString, characteristic.description, characteristic.properties, [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
    
    for (NSString *srvUUID in self.services) {
        NSMutableArray *chrs = [self.dataSource objectForKey:srvUUID];
        
        NSArray *tmpChrs = [NSArray arrayWithArray:chrs];
        for (CBCharacteristic *chr in tmpChrs) {
            if ([chr.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString]) {
                NSInteger index = [chrs indexOfObject:chr];
                [chrs replaceObjectAtIndex:index withObject:characteristic];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
        }
    }
}

#pragma mark - 懒加载
- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    
    return _peripherals;
}

- (NSMutableArray *)services
{
    if (!_services) {
        _services = [NSMutableArray array];
    }
    
    return _services;
}

- (NSMutableDictionary *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    
    return _dataSource;
}

@end
