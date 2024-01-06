module main

import discord
import strconv

fn run_testbot(token string, _ []string) ! {
	mut c := discord.bot(token,
		intents: .message_content | .guild_messages | .guild_message_reactions | .direct_message_reactions // | .guild_message_typing
		presence: discord.UpdatePresenceParams{
			activities: [
				discord.Activity{
					typ: .custom
					name: 'Custom Status'
					state: discord.some('Testing discord.v')
				},
			]
			status: .dnd
		}
		settings: .dont_cut_debug
		debug: true
	)
	app := c.fetch_my_application() or { discord.Application{} }
	c.bulk_overwrite_global_application_commands(app.id, [
		discord.CreateApplicationCommandParams{
			name: 'greet'
			description: 'Greet'
			options: [
				discord.ApplicationCommandOption{
					name: 'user'
					description: 'The user to greet'
					typ: .user
				},
			]
		},
	]) or {}
	c.events.on_interaction_create.listen(fn (event discord.InteractionCreateEvent) ! {
		event.creator.create_interaction_response(event.interaction.id, event.interaction.token,
			discord.ModalInteractionResponse{
			title: 'Your favorites?'
			custom_id: 'my_modal'
			components: [
				discord.ActionRow{
					components: [
						discord.TextInput{
							label: 'Favorite color'
							custom_id: 'favorite_color'
						},
					]
				},
				discord.ActionRow{
					components: [
						discord.TextInput{
							label: 'Favorite programming language'
							custom_id: 'favorite_programming_language'
						},
					]
				},
			]
		})!
	})
	c.events.on_ready.listen(fn (event discord.ReadyEvent) ! {
		println('Logged as ${event.user.username}! Bot has ${event.guilds.len} guilds')
	})
	c.events.on_message_create.listen(fn (event discord.MessageCreateEvent) ! {
		prefix := 'dv!'
		if !event.message.content.starts_with(prefix) {
			return
		}
		args := event.message.content[prefix.len..].split(' ')
		match args[0] or { '' } {
			'square' {
				if args.len != 2 {
					event.creator.create_message(event.message.channel_id,
						content: 'Specify argument, e.g. !square 7'
					)!
					return
				}
				i := strconv.atoi(args[1]) or {
					event.creator.create_message(event.message.channel_id,
						content: 'Invalid integer'
					)!
					return
				}
				event.creator.create_message(event.message.channel_id,
					content: (i * i).str()
					message_reference: discord.MessageReference{
						message_id: event.message.id
					}
				)!
			}
			'ping' {
				event.creator.create_message(event.message.channel_id,
					content: 'Pong'
					message_reference: discord.MessageReference{
						message_id: event.message.id
					}
				)!
			}
			'guild' {
				guild_id := event.message.guild_id
				dump(event.creator.fetch_guild(guild_id or {
					event.creator.create_message(event.message.channel_id,
						content: 'Not an guild'
						message_reference: discord.MessageReference{
							message_id: event.message.id
						}
					) or {
						eprintln('message ${err}')
						return
					}
					return
				}) or {
					eprintln('guild ${err}')
					return
				})
				event.creator.create_message(event.message.channel_id,
					content: 'Dumped!'
					message_reference: discord.MessageReference{
						message_id: event.message.id
					}
				)!
			}
			'disconnect' {
				mut c := event.creator
				c.ws.close(1000, 'discord')!
			}
			'webhook' {
				println('asdsad')
				// i dont care about webhook.
				event.creator.execute_webhook(1191507563443912755, '3G9KkD27pnBA3M2aybzKcCa9TtV5yci5XTb8gUA-DCEU8NZl9x6MxIchYjv1CiDZNNGs',
					content: 'Hey'
				)!
			}
			'bio' {
				if event.message.author.id != 1073325901825187841 {
					event.creator.create_message(event.message.channel_id, content: 'Ask my creator')!
					return
				}
				event.creator.edit_my_application(description: args[1..].join(' '))!
				event.creator.create_message(event.message.channel_id, content: 'Changed')!
			}
			else {}
		}
	})
	c.events.on_typing_start.listen(fn (event discord.TypingStartEvent) ! {
		println('typing')
		// event.creator.create_message(event.channel_id, content: "i see, you're typing something, <@${event.user_id}>")!
	})
	c.events.on_presence_update.listen(fn (event discord.PresenceUpdateEvent) ! {
		dump(event.presence)
	})
	c.launch()!
}
