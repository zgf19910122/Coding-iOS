//
//  ProjectTopicsView.m
//  Coding_iOS
//
//  Created by 王 原闯 on 14-8-20.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#import "ProjectTopicsView.h"
#import "TopicListView.h"
#import "Coding_NetAPIManager.h"
#import "ProjectTopicLabel.h"

@interface ProjectTopicsView ()
{
    NSArray *_one;
    NSMutableArray *_two;
    NSArray *_three;
    NSArray *_total;
    NSMutableArray *_oneNumber;
    NSMutableArray *_twoNumber;
    NSArray *_totalNumber;
    NSMutableArray *_totalIndex;
    NSInteger _segIndex;
}

@property (nonatomic, strong) Project *myProject;
@property (nonatomic, copy) ProjectTopicBlock block;
@property (strong, nonatomic) XTSegmentControl *mySegmentControl;
@property (strong, nonatomic) ProjectTopicListView *mylistView;

@property (strong, nonatomic) NSMutableArray *labels;

@end

@implementation ProjectTopicsView

- (id)initWithFrame:(CGRect)frame
            project:(Project *)project
              block:(ProjectTopicBlock)block
       defaultIndex:(NSInteger)index
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _myProject = project;
        _block = block;

        ProjectTopics *curProTopics = [ProjectTopics topicsWithPro:_myProject queryType:0];
        _mylistView = [[ProjectTopicListView alloc] initWithFrame:CGRectMake(0, kMySegmentControl_Height, kScreen_Width, self.frame.size.height - kMySegmentControl_Height)
                                                     projectTopics:curProTopics
                                                            block:_block];
        [self addSubview:_mylistView];
        [_mylistView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(kMySegmentControl_Height, 0, 0, 0));
        }];
        
        // 添加滑块
        _one = @[@"全部讨论", @"我的讨论"];
        _two = [NSMutableArray arrayWithObjects:@"全部标签", nil];
        _three = @[@"最后评论排序", @"发布时间排序", @"热门排序"];
        _total = @[_one, _two, _three];
        _oneNumber = [NSMutableArray arrayWithObjects:@0, @0, nil];
        _twoNumber = [NSMutableArray arrayWithObjects:@0, nil];
       _totalNumber = @[_oneNumber, _twoNumber];
        _totalIndex = [NSMutableArray arrayWithObjects:@0, @0, @0, nil];
        __weak typeof(self) weakSelf = self;
        self.mySegmentControl = [[XTSegmentControl alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, kMySegmentControl_Height)
                                                                  Items:@[_one[0], _two[0], _three[0]]
                                                               withIcon:YES
                                                          selectedBlock:^(NSInteger index) {
                                                              [weakSelf openList:index];
                                                          }];
        [self addSubview:self.mySegmentControl];
        
        _labels = [[NSMutableArray alloc] initWithCapacity:4];

    }
    return self;
}

- (void)refreshToQueryData
{
    [self sendLabelRequest];
    [self sendCountRequest];
    [_mylistView refreshToQueryData];
}

- (NSString *)toLabelPath
{
    return [NSString stringWithFormat:@"api/project/%d/topic/label?withCount=true", _myProject.id.intValue];
}

- (NSString *)toCountPath
{
    return [NSString stringWithFormat:@"api/project/%d/topic/count", _myProject.id.intValue];
}

- (void)sendLabelRequest
{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_ProjectTopicLabel_WithPath:[self toLabelPath] andBlock:^(id data, NSError *error) {
        if (data) {
            [weakSelf parseLabelInfo:data];
        }
    }];
}

- (void)sendCountRequest
{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_ProjectTopic_Count_WithPath:[self toCountPath] andBlock:^(id data, NSError *error) {
        if (data) {
            [weakSelf parseCountInfo:data];
        }
    }];
}

- (void)parseLabelInfo:(NSArray *)labelInfo
{
    [_labels removeAllObjects];
    [_labels addObjectsFromArray:labelInfo];
    [_two removeAllObjects];
    [_two addObject:@"全部标签"];
    [_twoNumber removeAllObjects];
    [_twoNumber addObject:_oneNumber[0]];
    for (ProjectTopicLabel *lbl in _labels) {
        [_two addObject:lbl.name];
        [_twoNumber addObject:lbl.count];
    }
}

- (void)parseCountInfo:(NSDictionary *)dic
{
    _oneNumber[0] = [dic objectForKey:@"all"];
    _oneNumber[1] = [dic objectForKey:@"my"];
    _twoNumber[0] = [dic objectForKey:@"all"];
}

- (void)changeIndex:(NSInteger)index withSegmentIndex:(NSInteger)segmentIndex
{
    [_totalIndex replaceObjectAtIndex:segmentIndex withObject:[NSNumber numberWithInteger:index]];
    [self.mySegmentControl setTitle:_total[segmentIndex][index] withIndex:segmentIndex];

    if ([_totalIndex[1] integerValue] > 0) {
        ProjectTopicLabel *lbl = _labels[[_totalIndex[1] integerValue] - 1];
        [_mylistView setOrder:[_totalIndex[2] integerValue] withLabelID:lbl.id andType:[_totalIndex[0] integerValue]];
    } else {
        [_mylistView setOrder:[_totalIndex[2] integerValue] withLabelID:@0 andType:[_totalIndex[0] integerValue]];
    }
}

- (void)openList:(NSInteger)segmentIndex
{
    TopicListView *lView = (TopicListView *)[self viewWithTag:9898];
    if (!lView) {
        _segIndex = segmentIndex;
        NSArray *lists = (NSArray *)_total[segmentIndex];
        CGRect rect = CGRectMake(0, kMySegmentControl_Height, kScreen_Width, self.frame.size.height - kMySegmentControl_Height);

        NSArray *nAry = nil;
        if (segmentIndex == 0 || segmentIndex == 1) {
            nAry = _totalNumber[segmentIndex];
        }
        __weak typeof(self) weakSelf = self;
        TopicListView *listView = [[TopicListView alloc] initWithFrame:rect
                                                                titles:lists
                                                               numbers:nAry
                                                          defaultIndex:[_totalIndex[segmentIndex] integerValue]
                                                         selectedBlock:^(NSInteger index) {
                                                             [weakSelf changeIndex:index withSegmentIndex:segmentIndex];
                                                         }];
        listView.tag = 9898;
        [self addSubview:listView];
        [listView showBtnView];
    } else if (_segIndex != segmentIndex) {
        _segIndex = segmentIndex;
        
        NSArray *nAry = nil;
        if (segmentIndex == 0 || segmentIndex == 1) {
            nAry = _totalNumber[segmentIndex];
        }
        NSArray *lists = (NSArray *)_total[segmentIndex];
        __weak typeof(self) weakSelf = self;
        [lView changeWithTitles:lists
                        numbers:nAry
                   defaultIndex:[_totalIndex[segmentIndex] integerValue]
                  selectedBlock:^(NSInteger index) {
                       [weakSelf changeIndex:index withSegmentIndex:segmentIndex];
                   }];
    } else {
        [lView hideBtnView];
    }
}

@end
