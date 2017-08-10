//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextInputbar.h"
#import "SLKTextView.h"
#import "SLKInputAccessoryView.h"

#import "SLKTextView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SLKTextInputbarDidMoveNotification =   @"SLKTextInputbarDidMoveNotification";

@interface SLKTextInputbar ()

@property (nonatomic, strong) NSLayoutConstraint *textViewBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *contentViewHC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonTopMarginC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *editorContentViewHC;

@property (nonatomic, strong) NSLayoutConstraint *leftButton1WC;
@property (nonatomic, strong) NSLayoutConstraint *leftButton1HC;

@property (nonatomic, strong) NSLayoutConstraint *leftButton2WC;
@property (nonatomic, strong) NSLayoutConstraint *leftButton2HC;

@property (nonatomic, strong) NSLayoutConstraint *leftButton3WC;
@property (nonatomic, strong) NSLayoutConstraint *leftButton3HC;

@property (nonatomic, strong) NSLayoutConstraint *leftButtonBottomMarginC1;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonBottomMarginC2;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonBottomMarginC3;


@property (nonatomic, strong) NSArray *charCountLabelVCs;

@property (nonatomic, strong) UILabel *charCountLabel;

@property (nonatomic) CGPoint previousOrigin;

@property (nonatomic, strong) Class textViewClass;

@property (nonatomic, getter=isHidden) BOOL hidden; // Required override
@property (nonatomic, strong) SLKTextView *hiddenTextField;
@property (nonatomic, strong) UITextField *inputField;
@end

@implementation SLKTextInputbar
@synthesize textView = _textView;
@synthesize contentView = _contentView;
@synthesize inputAccessoryView = _inputAccessoryView;
@synthesize hidden = _hidden;

#pragma mark - Initialization

- (instancetype)initWithTextViewClass:(Class)textViewClass
{
    if (self = [super init]) {
        self.textViewClass = textViewClass;
        [self slk_commonInit];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self slk_commonInit];
    }
    return self;
}

- (void)slk_commonInit
{
    self.charCountLabelNormalColor = [UIColor lightGrayColor];
    self.charCountLabelWarningColor = [UIColor redColor];
    
    self.autoHideRightButton = YES;
    self.editorContentViewHeight = 38.0;
    self.contentInset = UIEdgeInsetsMake(5.0, 8.0, 5.0, 8.0);
    
    [self addSubview:self.editorContentView];
    [self addSubview:self.flipButton];
    [self addSubview:self.leftButton1];
    [self addSubview:self.leftButton2];
    [self addSubview:self.leftButton3];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    [self addSubview:self.charCountLabel];
    [self addSubview:self.contentView];
    [self addSubview:self.hiddenTextField];
    
    [self slk_setupViewConstraints];
    [self slk_updateConstraintConstants];
    
    self.counterStyle = SLKCounterStyleNone;
    self.counterPosition = SLKCounterPositionTop;
    
    [self slk_registerNotifications];
    
    [self slk_registerTo:self.layer forSelector:@selector(position)];
    [self slk_registerTo:self.flipButton.imageView forSelector:@selector(image)];
    [self slk_registerTo:self.rightButton.titleLabel forSelector:@selector(font)];
}


#pragma mark - UIView Overrides

- (void)layoutIfNeeded
{
    if (self.constraints.count == 0 || !self.window) {
        return;
    }
    
    [self slk_updateConstraintConstants];
    [super layoutIfNeeded];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self minimumInputbarHeight]);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (SLKTextView *)textView
{
    if (!_textView) {
        Class class = self.textViewClass ? : [SLKTextView class];
        
        _textView = [[class alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0];
        _textView.maxNumberOfLines = [self slk_defaultNumberOfLines];
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, -1.0, 0.0, 1.0);
        _textView.textContainerInset = UIEdgeInsetsMake(8.0, 4.0, 8.0, 0.0);
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.borderWidth = 0.5;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
    }
    return _textView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}

- (SLKInputAccessoryView *)inputAccessoryView
{
    if (!_inputAccessoryView) {
        _inputAccessoryView = [[SLKInputAccessoryView alloc] initWithFrame:CGRectZero];
        _inputAccessoryView.backgroundColor = [UIColor clearColor];
        _inputAccessoryView.userInteractionEnabled = NO;
    }
    
    return _inputAccessoryView;
}

- (UIButton *)flipButton
{
    if (!_flipButton) {
        _flipButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _flipButton.translatesAutoresizingMaskIntoConstraints = NO;
        _flipButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_flipButton addTarget:self action:@selector(didPressLeftButton:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _flipButton;
}

- (UIButton *)leftButton1
{
    if (!_leftButton1) {
        _leftButton1 = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton1.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton1.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton1;
}

- (UIButton *)leftButton2
{
    if (!_leftButton2) {
        _leftButton2 = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton2.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton2.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton2;
}

- (UIButton *)leftButton3
{
    if (!_leftButton3) {
        _leftButton3 = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton3.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton3.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton3;
}



- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _rightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Send", nil);
        
        [_rightButton setTitle:title forState:UIControlStateNormal];
    }
    return _rightButton;
}

- (UITextView *)hiddenTextField {
    if (!_hiddenTextField) {
        _hiddenTextField = [[SLKTextView alloc] init];
    }
    return _hiddenTextField;
}

- (UIView *)editorContentView
{
    if (!_editorContentView) {
        _editorContentView = [UIView new];
        _editorContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _editorContentView.backgroundColor = self.backgroundColor;
        _editorContentView.clipsToBounds = YES;
        _editorContentView.hidden = YES;
        
        [_editorContentView addSubview:self.editorTitle];
        [_editorContentView addSubview:self.editorLeftButton];
        [_editorContentView addSubview:self.editorRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editorLeftButton,
                                @"rightButton": self.editorRightButton,
                                };
        
        NSDictionary *metrics = @{@"left" : @(self.contentInset.left),
                                  @"right" : @(self.contentInset.right)
                                  };
        
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(60)]-(left)-[label(>=0)]-(right)-[rightButton(60)]-(<=right)-|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
    }
    return _editorContentView;
}

- (UILabel *)editorTitle
{
    if (!_editorTitle) {
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Editing Message", nil);
        
        _editorTitle.text = title;
    }
    return _editorTitle;
}

- (UIButton *)editorLeftButton
{
    if (!_editorLeftButton) {
        _editorLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editorLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Cancel", nil);
        
        [_editorLeftButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorLeftButton;
}

- (UIButton *)editorRightButton
{
    if (!_editorRightButton) {
        _editorRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editorRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editorRightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Save", nil);
        
        [_editorRightButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorRightButton;
}

- (UILabel *)charCountLabel
{
    if (!_charCountLabel) {
        _charCountLabel = [UILabel new];
        _charCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _charCountLabel.backgroundColor = [UIColor clearColor];
        _charCountLabel.textAlignment = NSTextAlignmentRight;
        _charCountLabel.font = [UIFont systemFontOfSize:11.0];
        
        _charCountLabel.hidden = NO;
    }
    return _charCountLabel;
}

- (BOOL)isHidden
{
    return _hidden;
}

- (CGFloat)minimumInputbarHeight
{
    CGFloat minimumHeight = self.textView.intrinsicContentSize.height;
    minimumHeight += self.contentInset.top;
    minimumHeight += self.slk_bottomMargin;
    
    return minimumHeight;
}

- (CGFloat)appropriateHeight
{
    CGFloat height = 0.0;
    CGFloat minimumHeight = [self minimumInputbarHeight];
    
    if (self.textView.numberOfLines == 1) {
        height = minimumHeight;
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height = [self slk_inputBarHeightForLines:self.textView.numberOfLines];
    }
    else {
        height = [self slk_inputBarHeightForLines:self.textView.maxNumberOfLines];
    }
    
    if (height < minimumHeight) {
        height = minimumHeight;
    }
    
    if (self.isEditing) {
        height += self.editorContentViewHeight;
    }
    
    return roundf(height);
}

- (BOOL)limitExceeded
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.maxCharCount > 0 && text.length > self.maxCharCount) {
        return YES;
    }
    return NO;
}

- (CGFloat)slk_inputBarHeightForLines:(NSUInteger)numberOfLines
{
    CGFloat height = self.textView.intrinsicContentSize.height;
    height -= self.textView.font.lineHeight;
    height += roundf(self.textView.font.lineHeight*numberOfLines);
    height += self.contentInset.top;
    height += self.slk_bottomMargin;
    
    return height;
}

- (CGFloat)slk_bottomMargin
{
    CGFloat margin = self.contentInset.bottom;
    margin += self.slk_contentViewHeight;
    
    return margin;
}

- (CGFloat)slk_contentViewHeight
{
    if (!self.editing) {
        return CGRectGetHeight(self.contentView.frame);
    }
    
    return 0.0;
}

- (CGFloat)slk_appropriateRightButtonWidth
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }

    return [self.rightButton intrinsicContentSize].width;
}

- (CGFloat)slk_appropriateRightButtonMargin
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    
    return self.contentInset.right;
}

- (NSUInteger)slk_defaultNumberOfLines
{
    if (SLK_IS_IPAD) {
        return 8;
    }
    else if (SLK_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.editorContentView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton == hide) {
        return;
    }
    
    _autoHideRightButton = hide;
    
    self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];

    [self layoutIfNeeded];
}

- (void)setContentInset:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, insets)) {
        return;
    }
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, UIEdgeInsetsZero)) {
        _contentInset = insets;
        return;
    }
    
    _contentInset = insets;
    
    // Add new constraints
    [self removeConstraints:self.constraints];
    [self slk_setupViewConstraints];
    
    // Add constant values and refresh layout
    [self slk_updateConstraintConstants];
    
    [super layoutIfNeeded];
}

- (void)setEditing:(BOOL)editing
{
    if (self.isEditing == editing) {
        return;
    }
    
    _editing = editing;
    _editorContentView.hidden = !editing;
    
    self.contentViewHC.active = editing;
    
    [super setNeedsLayout];
    [super layoutIfNeeded];
}

- (void)setHidden:(BOOL)hidden
{
    // We don't call super here, since we want to avoid to visually hide the view.
    // The hidden render state is handled by the view controller.
    
    _hidden = hidden;
    
    if (!self.isEditing) {
        self.contentViewHC.active = hidden;
        
        [super setNeedsLayout];
        [super layoutIfNeeded];
    }
}

- (void)setCounterPosition:(SLKCounterPosition)counterPosition
{
    if (self.counterPosition == counterPosition && self.charCountLabelVCs) {
        return;
    }
    
    // Clears the previous constraints
    if (_charCountLabelVCs.count > 0) {
        [self removeConstraints:_charCountLabelVCs];
        _charCountLabelVCs = nil;
    }
    
    _counterPosition = counterPosition;
    
    NSDictionary *views = @{@"rightButton": self.rightButton,
                            @"charCountLabel": self.charCountLabel
                            };
    
    NSDictionary *metrics = @{@"top" : @(self.contentInset.top),
                              @"bottom" : @(-self.slk_bottomMargin/2.0)
                              };
    
    // Constraints are different depending of the counter's position type
    if (counterPosition == SLKCounterPositionBottom) {
        _charCountLabelVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[charCountLabel]-(bottom)-[rightButton]" options:0 metrics:metrics views:views];
    }
    else {
        _charCountLabelVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top@750)-[charCountLabel]-(>=0)-|" options:0 metrics:metrics views:views];
    }
    
    [self addConstraints:self.charCountLabelVCs];
}


#pragma mark - Text Editing

- (BOOL)canEditText:(NSString *)text
{
    if ((self.isEditing && [self.textView.text isEqualToString:text]) || self.isHidden) {
        return NO;
    }
    
    return YES;
}

- (void)beginTextEditing
{
    if (self.isEditing || self.isHidden) {
        return;
    }
    
    self.editing = YES;
    
    [self slk_updateConstraintConstants];
    
    if (!self.isFirstResponder) {
        [self layoutIfNeeded];
    }
}

- (void)endTextEdition
{
    if (!self.isEditing || self.isHidden) {
        return;
    }
    
    self.editing = NO;
    
    [self slk_updateConstraintConstants];
}


#pragma mark - Character Counter

- (void)slk_updateCounter
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *counter = nil;
    
    if (self.counterStyle == SLKCounterStyleNone) {
        counter = [NSString stringWithFormat:@"%lu", (unsigned long)text.length];
    }
    if (self.counterStyle == SLKCounterStyleSplit) {
        counter = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)text.length, (unsigned long)self.maxCharCount];
    }
    if (self.counterStyle == SLKCounterStyleCountdown) {
        counter = [NSString stringWithFormat:@"%ld", (long)(text.length - self.maxCharCount)];
    }
    if (self.counterStyle == SLKCounterStyleCountdownReversed)
    {
        counter = [NSString stringWithFormat:@"%ld", (long)(self.maxCharCount - text.length)];
    }
    
    self.charCountLabel.text = counter;
    self.charCountLabel.textColor = [self limitExceeded] ? self.charCountLabelWarningColor : self.charCountLabelNormalColor;
}


#pragma mark - Notification Events

- (void)slk_didChangeTextViewText:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    // Updates the char counter label
    if (self.maxCharCount > 0) {
        [self slk_updateCounter];
    }
    
    if (self.autoHideRightButton && !self.isEditing)
    {
        CGFloat rightButtonNewWidth = [self slk_appropriateRightButtonWidth];
        
        // Only updates if the width did change
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        [self.rightButton layoutIfNeeded]; // Avoids the right button to stretch when animating the constraint changes
        
        BOOL bounces = self.bounces && [self.textView isFirstResponder];
        
        if (self.window) {
            [self slk_animateLayoutIfNeededWithBounce:bounces
                                              options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                                           animations:NULL];
        }
        else {
            [self layoutIfNeeded];
        }
    }
}

- (void)slk_didChangeTextViewContentSize:(NSNotification *)notification
{
    if (self.maxCharCount > 0) {
        BOOL shouldHide = (self.textView.numberOfLines == 1) || self.editing;
        self.charCountLabel.hidden = shouldHide;
    }
}

- (void)slk_didChangeContentSizeCategory:(NSNotification *)notification
{
    if (!self.textView.isDynamicTypeEnabled) {
        return;
    }
    
    [self layoutIfNeeded];
}

- (void)slk_didBeginEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    CGSize leftButtonSize = [self.flipButton imageForState:self.flipButton.state].size;
    self.leftButtonWC.constant = leftButtonSize.width;
    self.leftButton1WC.constant = 0;
    self.leftButton2WC.constant = 0;
    self.leftButton3WC.constant = 0;
    self.leftButton1HC.constant = 0;
    self.leftButton2HC.constant = 0;
    self.leftButton3HC.constant = 0;

    // Do something
}


- (void)slk_didEndEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    self.leftButtonWC.constant = 0;

    CGSize leftButtonSize1 = [self.flipButton imageForState:self.leftButton1.state].size;
    CGSize leftButtonSize2 = [self.flipButton imageForState:self.leftButton2.state].size;
    CGSize leftButtonSize3 = [self.flipButton imageForState:self.leftButton3.state].size;
    self.leftButton1WC.constant = leftButtonSize1.height;
    self.leftButton2WC.constant = leftButtonSize2.height;
    self.leftButton3WC.constant = leftButtonSize3.height;
    self.leftButton1HC.constant = leftButtonSize1.width;
    self.leftButton2HC.constant = leftButtonSize2.width;
    self.leftButton3HC.constant = leftButtonSize3.width;

    // Do something
}

- (void)didPressLeftButton:(UIButton *)btn {
    if (self.textView.isFirstResponder) {
        [self.hiddenTextField becomeFirstResponder];
    }
}

#pragma mark - View Auto-Layout

- (void)slk_setupViewConstraints
{
    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.flipButton,
                            @"leftButton1": self.leftButton1,
                            @"leftButton2": self.leftButton2,
                            @"leftButton3": self.leftButton3,
                            @"rightButton": self.rightButton,
                            @"editorContentView": self.editorContentView,
                            @"charCountLabel": self.charCountLabel,
                            @"contentView": self.contentView,
                            };
    
    NSDictionary *metrics = @{@"top" : @(self.contentInset.top),
                              @"left" : @(self.contentInset.left),
                              @"right" : @(self.contentInset.right),
                              @"padding":@(4)
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(0)]-(<=padding)-[leftButton1(0)]-(padding)-[leftButton2(0)]-(padding)-[leftButton3(0)]-(<=padding)-[textView]-(right)-[rightButton(0)]-(right)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton1(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton2(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton3(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[rightButton]-(<=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left@250)-[charCountLabel(<=50@1000)]-(right@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[editorContentView(0)]-(<=top)-[textView(0@999)]-(0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[editorContentView]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView(0)]|" options:0 metrics:metrics views:views]];
    
    self.textViewBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.textView];
    self.editorContentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.editorContentView secondItem:nil];
    self.contentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.contentView secondItem:nil];;
    self.contentViewHC.active = NO; // Disabled by default, so the height is calculated with the height of its subviews
    
    self.leftButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.flipButton secondItem:nil];
    self.leftButtonHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.flipButton secondItem:nil];
    
    self.leftButton1WC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton1 secondItem:nil];
    self.leftButton1HC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton1 secondItem:nil];

    self.leftButton2WC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton2 secondItem:nil];
    self.leftButton2HC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton2 secondItem:nil];

    self.leftButton3WC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton3 secondItem:nil];
    self.leftButton3HC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton3 secondItem:nil];

    self.leftButtonBottomMarginC1 = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton1];
    self.leftButtonBottomMarginC2 = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton2];
    self.leftButtonBottomMarginC3 = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton3];
    
    self.leftButtonBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.flipButton];

    self.leftMarginWC = [[self slk_constraintsForAttribute:NSLayoutAttributeLeading] firstObject];
    
    self.rightButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.rightButton secondItem:nil];
    self.rightMarginWC = [[self slk_constraintsForAttribute:NSLayoutAttributeTrailing] firstObject];
    
    self.rightButtonTopMarginC = [self slk_constraintForAttribute:NSLayoutAttributeTop firstItem:self.rightButton secondItem:self];
    self.rightButtonBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.rightButton];
}

- (void)slk_updateConstraintConstants
{
    CGFloat zero = 0.0;
    
    self.textViewBottomMarginC.constant = self.slk_bottomMargin;
    self.leftButton1WC.constant = zero;
    self.leftButton1HC.constant = zero;
    
    self.leftButton2WC.constant = zero;
    self.leftButton2HC.constant = zero;
    
    self.leftButton3WC.constant = zero;
    self.leftButton3HC.constant = zero;

    if (self.isEditing)
    {
        self.editorContentViewHC.constant = self.editorContentViewHeight;
        
        self.leftButtonWC.constant = zero;
        self.leftButtonHC.constant = zero;
        self.leftMarginWC.constant = zero;
        self.leftButtonBottomMarginC.constant = zero;
        self.rightButtonWC.constant = zero;
        self.rightMarginWC.constant = zero;
        

    }
    else {
        self.editorContentViewHC.constant = zero;
        
        CGSize leftButtonSize = [self.flipButton imageForState:self.flipButton.state].size;
        
        if (leftButtonSize.width > 0) {
            self.leftButtonHC.constant = roundf(leftButtonSize.height);
            self.leftButtonBottomMarginC.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0) + self.slk_contentViewHeight / 2.0;
            
            self.leftButtonBottomMarginC1.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0) + self.slk_contentViewHeight / 2.0;
            self.leftButtonBottomMarginC2.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0) + self.slk_contentViewHeight / 2.0;
            self.leftButtonBottomMarginC3.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0) + self.slk_contentViewHeight / 2.0;
        }
        
        self.leftButtonWC.constant = roundf(leftButtonSize.width);
        self.leftMarginWC.constant = (leftButtonSize.width > 0) ? self.contentInset.left : zero;
        
        self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        
        CGFloat rightVerMargin = (self.intrinsicContentSize.height - self.slk_contentViewHeight - self.rightButton.intrinsicContentSize.height) / 2.0;
        CGFloat rightVerBottomMargin = rightVerMargin + self.slk_contentViewHeight;
        
        self.rightButtonTopMarginC.constant = rightVerMargin;
        self.rightButtonBottomMarginC.constant = rightVerBottomMargin;
        
    }
}

- (BOOL)isFirstResponder {
    if ([self.textView isFirstResponder] || [self.hiddenTextField isFirstResponder]) {
        return  YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    return [self.textView resignFirstResponder] || [self.hiddenTextField resignFirstResponder];
}
#pragma mark - Observers

- (void)slk_registerTo:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object addObserver:self forKeyPath:NSStringFromSelector(selector) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (void)slk_unregisterFrom:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object removeObserver:self forKeyPath:NSStringFromSelector(selector)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.layer] && [keyPath isEqualToString:NSStringFromSelector(@selector(position))]) {
        
        if (!CGPointEqualToPoint(self.previousOrigin, self.frame.origin)) {
            self.previousOrigin = self.frame.origin;
            [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextInputbarDidMoveNotification object:self userInfo:@{@"origin": [NSValue valueWithCGPoint:self.previousOrigin]}];
        }
    }
    else if (([object isEqual:self.flipButton.imageView] || [object isEqual:self.leftButton1.imageView] )&& [keyPath isEqualToString:NSStringFromSelector(@selector(image))]) {
        
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        UIImage *oldImage = change[NSKeyValueChangeOldKey];
        
        if (![newImage isEqual:oldImage]) {
            [self slk_updateConstraintConstants];
        }
    }
    else if ([object isEqual:self.rightButton.titleLabel] && [keyPath isEqualToString:NSStringFromSelector(@selector(font))]) {
        
        [self slk_updateConstraintConstants];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - NSNotificationCenter registration

- (void)slk_registerNotifications
{
    [self slk_unregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeContentSizeCategory:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];

}

- (void)slk_unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];

}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_unregisterNotifications];
    
    [self slk_unregisterFrom:self.layer forSelector:@selector(position)];
    [self slk_unregisterFrom:self.flipButton.imageView forSelector:@selector(image)];
    [self slk_unregisterFrom:self.rightButton.titleLabel forSelector:@selector(font)];
}

@end
