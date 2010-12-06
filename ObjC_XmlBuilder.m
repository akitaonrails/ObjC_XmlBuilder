#import <Foundation/Foundation.h>

@interface XmlBuilder : NSObject
{
    NSMutableString* buffer;
    int indentationLevel;
}

@property (retain) NSMutableString* buffer;
@property (assign) int indentationLevel;

@end

@implementation XmlBuilder

@synthesize buffer, indentationLevel;

- (id) init {
    self = [super init];
    if (self) {
        self.buffer = [[NSMutableString alloc] init];
        self.indentationLevel = 0;
    }
    return self;
}

- (void) dealloc {
    [buffer release];
    [super dealloc];
}

#pragma mark -
#pragma mark Method Missing Support

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // não importa o retorno porque não vamos usar essa assinatura
    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

/*
 Convenção para métodos dinâmicos:
 
 - (id) entityTemplate:(NSString*)value;
 
 - (id) blockTemplate:(id (^)(id))block;
 
 - (id) entityTemplateWithAttributes:(NSString*)value attributes:(NSArray*)attributes;
 
 - (id) blockTemplateWithAttributes:(NSArray*)attributes block:(id (^)(id))block;
 
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSString* method = NSStringFromSelector([anInvocation selector]);

    // limpa o nome do método e ao mesmo tempo recupera suas propriedades
    BOOL hasAttributes = [method hasSuffix:@"WithAttributes:"];
    method = [method stringByReplacingOccurrencesOfString:@"WithAttributes" withString:@""];
    
    BOOL hasBlock = [method hasSuffix:@"Block:"];
    method = [method stringByReplacingOccurrencesOfString:@"Block" withString:@""];
    method = [method stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    // calcula a indentação atual
    int tabsLength = self.indentationLevel * 2;
    NSMutableString* tabs = [NSMutableString stringWithCapacity:tabsLength];
    int i;
    for ( i = 0 ; i < tabsLength; i ++ ) {
        [tabs appendString:@" "];
    }
    
    if (hasBlock) {
        id (^block)(id);
        if (hasAttributes) {
            // @TODO
            [anInvocation getArgument:&block atIndex:3];
        } else {
            [anInvocation getArgument:&block atIndex:2];            
        }
        [buffer appendFormat:@"%@<%@>\n", tabs, method];
        self.indentationLevel = self.indentationLevel + 1;
        block(self);
        self.indentationLevel = self.indentationLevel - 1;
        [buffer appendFormat:@"%@</%@>\n", tabs, method];
    } else {
        NSString* value;
        [anInvocation getArgument:&value atIndex:2];
        if (hasAttributes) {
            // @TODO
        }
        [buffer appendFormat:@"%@<%@>\n%@%@%@\n%@</%@>\n", tabs, method, tabs, @"  ", value, tabs, method];
    }    
}

@end



int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    XmlBuilder* xml = [[XmlBuilder alloc] init];
    [xml htmlBlock:^(XmlBuilder* h) {
        [h bodyBlock:^(XmlBuilder* b) {
            [b h1:@"Hello World"];
            [b p:@"This is a paragraph."];
            [b tableBlock:^(XmlBuilder* t) {
                [t trBlock:^(XmlBuilder* tr) {
                    [tr td:@"column"];
                }];
            }];            
        }];
    }];
    NSLog(@"%@", [xml buffer]);
    [pool drain];
    return 0;
}
